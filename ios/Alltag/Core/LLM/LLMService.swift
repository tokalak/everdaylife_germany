import Foundation

/// The `Core/LLM` facade injected into the app (P0-07).
///
/// Bundles the four moving parts behind one value so feature code and DI don't
/// reassemble them: the swappable ``LLMEngine`` (A-21), the ``ModelProvisioner``
/// for first-run readiness (A-22…A-26), the ``ModelStore`` for storage queries
/// (Settings), and the recorded ``RuntimeDecision`` (OQ-14).
///
/// `engine` is a ``StubLLMEngine`` until the llama.cpp xcframework is vendored on
/// a real device (see ``LlamaCppEngine``); swapping it is the *only* change that
/// activates real inference, because everything above depends on the protocol.
struct LLMService: Sendable {
    let catalog: LLMModelCatalog
    let store: ModelStore
    let provisioner: ModelProvisioner
    let engine: any LLMEngine
    let runtime: RuntimeDecision

    /// Production wiring. Uses the v1 catalog, a URLSession downloader, and — for
    /// now — the stub engine, so the app composes and runs in the Simulator
    /// while download/management/capability machinery is real.
    static func live(catalog: LLMModelCatalog = .v1) throws -> LLMService {
        let store = try ModelStore()
        let provisioner = ModelProvisioner(
            catalog: catalog,
            store: store,
            downloader: URLSessionModelDownloader())
        return LLMService(
            catalog: catalog,
            store: store,
            provisioner: provisioner,
            engine: StubLLMEngine(),
            runtime: .current)
    }
}
