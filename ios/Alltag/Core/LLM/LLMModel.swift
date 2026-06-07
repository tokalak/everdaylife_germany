import Foundation

/// Quantisation level of an on-device weight file.
///
/// Smaller quants trade a little quality for a smaller download and lower RAM,
/// which is how we reach older/lower-RAM iPhones (A-25, OQ-8/OQ-11). The byte
/// sizes and RAM floors are **approximations isolated here as versioned content**
/// (X-06) — they are tuned by the A-28 eval harness and the supported-device
/// matrix, never hard-coded into views.
enum ModelQuant: String, Sendable, CaseIterable, Codable {
    /// Default: **Qwen3.5-0.8B** post-training 4-bit (`Q4_K_M`, ≈0.53 GB). A
    /// sub-1B instruct model whose tiny footprint runs on essentially every
    /// supported iPhone with a small KV cache — chosen as the shipping Decoder
    /// model (replaces the larger Gemma 4 E2B QAT builds below).
    case q4_K_M
    /// Legacy/retained: Unsloth dynamic **QAT** 4-bit Gemma 4 E2B
    /// (`UD-Q4_K_XL`, 2.62 GB). No longer shipped; kept as catalog metadata and
    /// as a generic quant tag in tests.
    case q4_K_XL
    /// Legacy/retained: mobile-mixture QAT 2-bit Gemma 4 E2B (`UD-Q2_K_XL`,
    /// ≈2.19 GB) for ~4 GB-RAM devices. No longer shipped.
    case q2_K_XL

    /// Suffix used in the GGUF filename (`…-<suffix>.gguf`).
    var fileSuffix: String {
        switch self {
        case .q4_K_M: "Q4_K_M"
        case .q4_K_XL: "UD-Q4_K_XL"
        case .q2_K_XL: "UD-Q2_K_XL"
        }
    }

    /// Exact on-disk size of the weight file, in bytes (a fast integrity gate
    /// before hashing — ``ModelVerifier`` requires an exact match).
    var approximateByteCount: Int64 {
        switch self {
        case .q4_K_M: 532_517_120      // ≈0.53 GB (Qwen3.5-0.8B-Q4_K_M)
        case .q4_K_XL: 2_620_368_960   // 2.62 GB (unsloth/gemma-4-E2B-it-qat-GGUF)
        case .q2_K_XL: 2_186_184_768   // ≈2.19 GB (mobile mixture)
        }
    }

    /// Minimum device physical RAM to run this quant with a small KV cache
    /// without thrashing (A-25/A-26). Weights must be resident plus headroom for
    /// the OS, the app, and a capped context window.
    ///
    /// These floors are matched against `ProcessInfo.physicalMemory`, which on
    /// real hardware reports a bit *below* the marketed nominal (iOS reserves
    /// some RAM): a "4 GB" iPhone reports ≈3.7 GiB, a "6 GB" one ≈5.5 GiB. So a
    /// floor of exactly the nominal binary size (e.g. `4 * 1024³`) would reject
    /// every device of that class. We therefore set each floor a notch below
    /// nominal — high enough to keep the next class down out (a 3 GB phone reports
    /// ≈2.9 GiB), low enough to admit the class we intend.
    var minimumDeviceMemory: UInt64 {
        switch self {
        case .q4_K_M: 3 * 1_024 * 1_024 * 1_024 / 2     // 1.5 GiB → ~2 GB-class devices (report ≈1.8 GiB)
        case .q4_K_XL: 5 * 1_024 * 1_024 * 1_024        // 5 GiB → ~6 GB-class devices (report ≈5.5 GiB)
        case .q2_K_XL: 7 * 1_024 * 1_024 * 1_024 / 2    // 3.5 GiB → ~4 GB-class devices (report ≈3.7 GiB)
        }
    }
}

/// Everything needed to locate and validate one on-device model file.
///
/// A spec is *data*, not behaviour: it describes the bundled artifact so that
/// ``ModelStore`` knows where to find it and ``ModelVerifier`` knows how to
/// validate it (A-22). The `sourceURL` is retained only so the dev-time
/// `scripts/fetch-model.sh` knows where to fetch the weights to bundle — the
/// app itself never downloads.
struct LLMModelSpec: Sendable, Equatable, Identifiable, Codable {
    /// Stable identifier, e.g. `gemma-4-e2b-it-q4_k_m`.
    let id: String
    /// Shown in readiness/Settings UI.
    let displayName: String
    /// Runtime that consumes this file (drives the engine choice).
    let runtime: LLMRuntime
    /// Quant level (nil for non-GGUF runtimes such as LiteRT-LM).
    let quant: ModelQuant?
    /// On-disk filename, e.g. `gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf`.
    let fileName: String
    /// Where to download it from (HF direct or a CDN mirror — OQ-10).
    let sourceURL: URL
    /// Expected size in bytes; a fast integrity check before hashing (A-22).
    let expectedByteCount: Int64
    /// Expected SHA-256 of the file, lowercase hex. `nil` until pinned for a
    /// release — size is still checked, and the verifier requires this before a
    /// build ships (gated by tests / release checklist).
    let sha256: String?
    /// KV-cache context window cap, well below Gemma's 128K to bound RAM
    /// (A-26) — Behörden letters are short.
    let contextWindowCap: Int

    /// Minimum device RAM to run this spec (from its quant, or a runtime floor).
    var minimumDeviceMemory: UInt64 {
        quant?.minimumDeviceMemory ?? (4 * 1_024 * 1_024 * 1_024)
    }
}

/// The set of models the app knows how to provision, plus the rules for picking
/// one for a device.
///
/// This is the single versioned source for model URLs/sizes/quants (X-06). It
/// carries both llama.cpp candidates we actually ship (primary + low-memory
/// fallback) and a record of Candidate B (LiteRT-LM) kept for the OQ-14 spike.
struct LLMModelCatalog: Sendable, Equatable {
    /// The shipping on-device model: Qwen3.5-0.8B GGUF `Q4_K_M` on llama.cpp.
    let primary: LLMModelSpec
    /// Mirror of ``primary``. Qwen3.5-0.8B is ~0.5 GB — small enough to run on
    /// every supported iPhone — so there is **no separate low-memory build**;
    /// this slot is retained for struct shape and points at the same spec.
    /// (``deliverable`` carries just the single model, below.)
    let lowMemoryFallback: LLMModelSpec
    /// Candidate B: the LiteRT-LM `.litertlm` artifact — recorded for the spike,
    /// not shipped unless the benchmark flips ``RuntimeDecision``.
    let candidateB: LLMModelSpec

    /// The quant the app prefers by default, independent of what a device *could*
    /// run. This separates **policy** (which quant we want) from **capability**
    /// (which quants fit). The capability gate honours this whenever the device
    /// can run it, only stepping down to a heavier-but-still-affordable quant if
    /// the default itself doesn't fit. Set it to the richest quant to get the
    /// old "best that fits" behaviour back (a one-line revert).
    let defaultQuant: ModelQuant

    /// Specs that can actually be served to a device — the capability gate walks
    /// this together with ``defaultQuant`` to pick the quant a device should run.
    /// There is a single shipping model (Qwen3.5-0.8B); ``lowMemoryFallback``
    /// mirrors it, so the deliverable set is just ``primary``.
    var deliverable: [LLMModelSpec] { [primary] }

    /// The spec for a given quant, if the catalog carries it.
    func spec(for quant: ModelQuant) -> LLMModelSpec? {
        deliverable.first { $0.quant == quant }
    }

    /// The v1 catalog. The shipping model is **Qwen3.5-0.8B `Q4_K_M`** — a
    /// sub-1B instruct model small enough (~0.53 GB) to run on essentially every
    /// supported iPhone (switched 2026-06-07 from the larger Gemma 4 E2B builds
    /// per the user). The Gemma `candidateB` (LiteRT-LM) record is kept for the
    /// OQ-14 spike. The SHA-256 is pinned to the file provided in `ios/Models/`.
    static let v1 = LLMModelCatalog(
        primary: qwen3_5_0_8B_Q4KM,
        // No separate low-memory build — Qwen3.5-0.8B already fits the lowest
        // supported device. Mirrors `primary`; see ``lowMemoryFallback``.
        lowMemoryFallback: qwen3_5_0_8B_Q4KM,
        candidateB: LLMModelSpec(
            id: "gemma-4-e2b-it-litertlm",
            displayName: "Gemma 4 E2B · LiteRT-LM",
            runtime: .liteRTLM,
            quant: nil,
            fileName: "gemma-4-E2B-it.litertlm",
            sourceURL: URL(
                string: "https://huggingface.co/google/gemma-4-E2B-it-litert-preview/resolve/main/gemma-4-E2B-it.litertlm")!,
            expectedByteCount: 2_590_000_000,
            sha256: nil,
            contextWindowCap: 8_192),
        defaultQuant: .q4_K_M)

    /// The single shipping on-device model — Unsloth's GGUF build
    /// ([`unsloth/Qwen3.5-0.8B-GGUF`](https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF)).
    /// `sourceURL` is only used by the dev-time `scripts/fetch-model.sh`; the app
    /// never downloads (hard rule) and the weights are provided in `ios/Models/`.
    private static let qwen3_5_0_8B_Q4KM = LLMModelSpec(
        id: "qwen3.5-0.8b-q4_k_m",
        displayName: "Qwen3.5 0.8B · Q4_K_M",
        runtime: .llamaCpp,
        quant: .q4_K_M,
        fileName: "Qwen3.5-0.8B-Q4_K_M.gguf",
        sourceURL: URL(
            string: "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf")!,
        expectedByteCount: ModelQuant.q4_K_M.approximateByteCount,
        sha256: "bd258782e35f7f458f8aced1adc053e6e92e89bc735ba3be89d38a06121dc517",
        contextWindowCap: 8_192)
}
