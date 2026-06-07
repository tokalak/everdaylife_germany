import Foundation

#if canImport(llama)
import llama

/// The production ``LLMEngine`` for Candidate A — Gemma 4 E2B GGUF on
/// `llama.cpp` with the Metal backend (``RuntimeDecision/current``).
///
/// **Active when the runtime is vendored.** `import llama` resolves only after
/// `scripts/build-llama-xcframework.sh` has produced `Vendor/llama.xcframework`
/// and the project was generated with `ALLTAG_LLAMA_RUNTIME=true` (see
/// `project.yml`). In that build this engine loads the provisioned GGUF and runs
/// real on-device inference; otherwise the `#else` branch below keeps the type
/// defined but inert so the app composes and falls back to ``StubLLMEngine``.
///
/// It honours the full ``LLMEngine`` contract: it **streams** decoded text as it
/// is produced, caps generation at ``LLMGenerationOptions/maxTokens`` and the
/// spec's `contextWindowCap` (A-26), translates ``LLMGenerationOptions/grammar``
/// into a llama.cpp **GBNF** sampler for guaranteed-valid JSON (A-27), is
/// **cancellable** (dropping the stream cancels mid-decode), and serialises
/// generations through an actor so a second concurrent call fails with
/// ``LLMError/busy`` (the single-inference guard).
///
/// The model is memory-mapped once and kept resident; a fresh context + sampler
/// is built per decode (cheap next to the ~2 GB load) so each letter starts from
/// a clean KV cache without depending on the churn-prone cache-reset C API.
///
/// Targets the modern, vocab-based llama.cpp C API (`llama_model_load_from_file`,
/// `llama_sampler_*`, `llama_*_vocab_*`); pin the runtime with `LLAMA_CPP_REF`.
struct LlamaCppEngine: LLMEngine {
    /// The provisioned, on-disk GGUF this engine loads (bundled default model).
    let modelURL: URL
    /// KV-cache context window cap (A-26), from the model's ``LLMModelSpec``.
    let contextWindowCap: Int
    private let runner: LlamaRunner

    init(modelURL: URL, contextWindowCap: Int) {
        self.modelURL = modelURL
        self.contextWindowCap = contextWindowCap
        self.runner = LlamaRunner(modelURL: modelURL, contextWindowCap: contextWindowCap)
    }

    func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error> {
        let runner = self.runner
        return AsyncThrowingStream { continuation in
            let task = Task {
                await runner.run(prompt, options: options, into: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Owns the resident `llama.cpp` model and serialises inference.
///
/// An `actor` so the model handle and the single-inference guard are race-free;
/// the synchronous decode loop runs inside actor isolation (which is exactly the
/// "one generation at a time" guarantee) and checks `Task.isCancelled` between
/// tokens so dropping the stream stops it promptly.
private actor LlamaRunner {
    private let modelURL: URL
    private let contextWindowCap: Int
    // `nonisolated(unsafe)`: freed from the (nonisolated) deinit, which is safe
    // because deinit runs only once all references are gone, after every
    // actor-isolated access has completed. All other access stays serialised by
    // the actor. Without this, Swift 6 rejects the deinit's non-Sendable access.
    private nonisolated(unsafe) var model: OpaquePointer?
    private var vocab: OpaquePointer?
    private var isGenerating = false

    /// `llama_backend_init()` is process-global and must run exactly once.
    private static let backendOnce: Void = { llama_backend_init() }()

    init(modelURL: URL, contextWindowCap: Int) {
        self.modelURL = modelURL
        self.contextWindowCap = contextWindowCap
    }

    deinit {
        if let model { llama_model_free(model) }
    }

    func run(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions,
        into continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        guard !isGenerating else {
            continuation.finish(throwing: LLMError.busy)
            return
        }
        isGenerating = true
        defer { isGenerating = false }
        do {
            try ensureModelLoaded()
            try decode(prompt, options: options, into: continuation)
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }

    /// Memory-maps the model once and caches its handle + vocab.
    private func ensureModelLoaded() throws {
        guard model == nil else { return }
        _ = LlamaRunner.backendOnce

        var params = llama_model_default_params()
        params.n_gpu_layers = 999   // offload everything to Metal on device

        let loaded = modelURL.path.withCString { llama_model_load_from_file($0, params) }
        guard let loaded else { throw LLMError.modelNotLoaded }
        guard let v = llama_model_get_vocab(loaded) else {
            llama_model_free(loaded)
            throw LLMError.modelNotLoaded
        }
        model = loaded
        vocab = v
    }

    /// Runs one generation: tokenise the Gemma-formatted prompt, evaluate it,
    /// then sample/decode token-by-token, streaming decoded UTF-8 as it forms.
    private func decode(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions,
        into continuation: AsyncThrowingStream<String, Error>.Continuation
    ) throws {
        guard let model, let vocab else { throw LLMError.modelNotLoaded }

        let threads = Int32(max(1, ProcessInfo.processInfo.processorCount - 1))
        var cparams = llama_context_default_params()
        cparams.n_ctx = UInt32(contextWindowCap)
        cparams.n_batch = UInt32(contextWindowCap)
        cparams.n_threads = threads
        cparams.n_threads_batch = threads
        guard let ctx = llama_init_from_model(model, cparams) else {
            throw LLMError.runtimeUnavailable
        }
        defer { llama_free(ctx) }

        guard let sampler = makeSampler(vocab: vocab, options: options) else {
            throw LLMError.runtimeUnavailable
        }
        defer { llama_sampler_free(sampler) }

        // Prompt → tokens (special tokens parsed so the chat markers bind; Qwen
        // defines no BOS, so `add_special` adds nothing here, which is correct).
        var tokens = tokenize(QwenChat.format(prompt), addBOS: true)
        guard !tokens.isEmpty, tokens.count < contextWindowCap else {
            throw LLMError.runtimeUnavailable
        }

        let evalOK = tokens.withUnsafeMutableBufferPointer { buf -> Bool in
            llama_decode(ctx, llama_batch_get_one(buf.baseAddress, Int32(buf.count))) == 0
        }
        guard evalOK else { throw LLMError.runtimeUnavailable }

        var nCur = Int32(tokens.count)
        var produced = 0
        var pending: [UInt8] = []   // holds bytes spanning a multi-token UTF-8 char

        while produced < options.maxTokens && nCur < Int32(contextWindowCap) {
            if Task.isCancelled { throw LLMError.cancelled }

            let token = llama_sampler_sample(sampler, ctx, -1)   // also accepts it
            if llama_vocab_is_eog(vocab, token) { break }

            pending.append(contentsOf: pieceBytes(token))
            if let text = String(bytes: pending, encoding: .utf8) {
                if !text.isEmpty { continuation.yield(text) }
                pending.removeAll(keepingCapacity: true)
            }
            produced += 1

            var next = token
            let stepOK = withUnsafeMutablePointer(to: &next) { p in
                llama_decode(ctx, llama_batch_get_one(p, 1)) == 0
            }
            guard stepOK else { throw LLMError.runtimeUnavailable }
            nCur += 1
        }

        // Flush any trailing bytes (e.g. a clipped multi-byte char), lossily.
        if !pending.isEmpty {
            let tail = String(decoding: pending, as: UTF8.self)
            if !tail.isEmpty { continuation.yield(tail) }
        }
    }

    /// Builds the sampler chain: GBNF grammar first (constrains the logits to
    /// the Decoder's JSON shape, A-27), then greedy for deterministic output
    /// (temperature 0) or temperature+dist otherwise.
    private func makeSampler(
        vocab: OpaquePointer,
        options: LLMGenerationOptions
    ) -> UnsafeMutablePointer<llama_sampler>? {
        guard let chain = llama_sampler_chain_init(llama_sampler_chain_default_params()) else {
            return nil
        }
        if let grammar = options.grammar {
            let g = grammar.withCString { gPtr in
                "root".withCString { rPtr in
                    llama_sampler_init_grammar(vocab, gPtr, rPtr)
                }
            }
            if let g { llama_sampler_chain_add(chain, g) }
        }
        if options.temperature <= 0 {
            llama_sampler_chain_add(chain, llama_sampler_init_greedy())
        } else {
            // Qwen3.5 (non-thinking) recommends top_k = 20; we also apply a small
            // min_p floor to trim the long tail on this 0.8B model (the docs use
            // min_p = 0, but a light relative floor guards against rare garbage
            // tokens). Order matches llama.cpp's example: truncate (top_k → min_p)
            // → temperature → sample.
            llama_sampler_chain_add(chain, llama_sampler_init_top_k(20))
            llama_sampler_chain_add(chain, llama_sampler_init_min_p(0.05, 1))
            llama_sampler_chain_add(chain, llama_sampler_init_temp(Float(options.temperature)))
            llama_sampler_chain_add(chain, llama_sampler_init_dist(0xFFFF_FFFF))
        }
        return chain
    }

    /// Tokenises `text`, growing the buffer if the first estimate is too small.
    private func tokenize(_ text: String, addBOS: Bool) -> [llama_token] {
        let byteLen = Int32(text.utf8.count)
        var capacity = Int(byteLen) + (addBOS ? 1 : 0) + 1
        var tokens = [llama_token](repeating: 0, count: capacity)
        var n = text.withCString { cstr in
            llama_tokenize(vocab, cstr, byteLen, &tokens, Int32(capacity), addBOS, true)
        }
        if n < 0 {
            capacity = Int(-n)
            tokens = [llama_token](repeating: 0, count: capacity)
            n = text.withCString { cstr in
                llama_tokenize(vocab, cstr, byteLen, &tokens, Int32(capacity), addBOS, true)
            }
        }
        return n > 0 ? Array(tokens.prefix(Int(n))) : []
    }

    /// Raw bytes of one token's piece (not necessarily valid UTF-8 on its own —
    /// callers buffer across tokens).
    private func pieceBytes(_ token: llama_token) -> [UInt8] {
        var buf = [CChar](repeating: 0, count: 64)
        var n = llama_token_to_piece(vocab, token, &buf, Int32(buf.count), 0, false)
        if n < 0 {
            buf = [CChar](repeating: 0, count: Int(-n))
            n = llama_token_to_piece(vocab, token, &buf, Int32(buf.count), 0, false)
        }
        guard n > 0 else { return [] }
        return buf.prefix(Int(n)).map { UInt8(bitPattern: $0) }
    }
}

/// Qwen ChatML instruction-format helper. Qwen3.5 uses the ChatML markers
/// `<|im_start|>` / `<|im_end|>` and has a native system role, so the task
/// instruction goes in its own system turn (kept separate from the user text).
/// The assistant turn is left open for generation; the model's `<|im_end|>` is
/// an end-of-generation token, so the caller's `llama_vocab_is_eog` check stops
/// the stream. Qwen defines no BOS token, so none is prepended.
private enum QwenChat {
    static func format(_ prompt: LLMPrompt) -> String {
        var text = ""
        if !prompt.system.isEmpty {
            text += "<|im_start|>system\n\(prompt.system)<|im_end|>\n"
        }
        text += "<|im_start|>user\n\(prompt.user)<|im_end|>\n"
        text += "<|im_start|>assistant\n"
        return text
    }
}

#else

/// Inert stand-in for the production ``LLMEngine`` when the llama.cpp runtime
/// has not been vendored (CI, the Simulator, a fresh checkout).
///
/// `import llama` fails to resolve until `scripts/build-llama-xcframework.sh`
/// produces `Vendor/llama.xcframework` and the project is generated with
/// `ALLTAG_LLAMA_RUNTIME=true`. Until then this build keeps the type defined so
/// the app composes, but it reports ``LLMError/runtimeUnavailable`` and
/// ``LLMService`` falls back to ``StubLLMEngine``. See the `#if canImport(llama)`
/// branch above for the real implementation that activates on a device build.
struct LlamaCppEngine: LLMEngine {
    let modelURL: URL
    let contextWindowCap: Int

    init(modelURL: URL, contextWindowCap: Int) {
        self.modelURL = modelURL
        self.contextWindowCap = contextWindowCap
    }

    func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish(throwing: LLMError.runtimeUnavailable) }
    }
}

#endif
