import Foundation

/// The `Core/LLM` facade injected into the app (P0-07).
///
/// Bundles the four moving parts behind one value so feature code and DI don't
/// reassemble them: the swappable ``LLMEngine`` (A-21), the ``ModelProvisioner``
/// for first-run readiness (A-22…A-26), the ``ModelStore`` for storage queries
/// (Settings), and the recorded ``RuntimeDecision`` (OQ-14).
///
/// `engine` is the real ``LlamaCppEngine`` whenever the llama.cpp runtime has
/// been vendored (`scripts/build-llama-xcframework.sh` + `ALLTAG_LLAMA_RUNTIME`)
/// and the device's default model is provisioned; otherwise it is a
/// ``StubLLMEngine``. Everything above depends only on the ``LLMEngine``
/// protocol, so this selection is the single seam that activates real inference.
struct LLMService: Sendable {
    let catalog: LLMModelCatalog
    let store: ModelStore
    let provisioner: ModelProvisioner
    let engine: any LLMEngine
    let runtime: RuntimeDecision

    /// Production wiring. Uses the v1 catalog and selects the engine via
    /// ``makeEngine(provisioner:)``: the real llama.cpp engine on a device build
    /// where the bundled default model is ready, the stub otherwise (Simulator/CI
    /// or a build without the vendored runtime). The model is bundled in the app,
    /// never downloaded.
    static func live(catalog: LLMModelCatalog = .v1) throws -> LLMService {
        let store = try ModelStore()
        let provisioner = ModelProvisioner(catalog: catalog, store: store)
        return LLMService(
            catalog: catalog,
            store: store,
            provisioner: provisioner,
            engine: makeEngine(provisioner: provisioner),
            runtime: .current)
    }

    /// Picks the on-device engine. When the llama.cpp runtime is linked
    /// (`#if canImport(llama)`) and the device's planned (default-quant) model is
    /// present and ready, loads it into a real ``LlamaCppEngine``. In every other
    /// case — runtime not vendored, device unsupported, or weights missing — it
    /// returns ``StubLLMEngine`` so the app still composes; the Decoder's
    /// readiness UI surfaces the unsupported/missing states before any decode.
    static func makeEngine(provisioner: ModelProvisioner) -> any LLMEngine {
        #if canImport(llama)
        if case let .ready(url) = provisioner.resolve(),
           let spec = provisioner.plannedSpec() {
            return LlamaCppEngine(modelURL: url, contextWindowCap: spec.contextWindowCap)
        }
        #endif
        return StubLLMEngine()
    }
}
