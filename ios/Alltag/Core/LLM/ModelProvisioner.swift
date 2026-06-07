import Foundation

/// The outcome of resolving on-device model readiness.
///
/// There is deliberately **no downloading/verifying state**: the app never
/// fetches weights at runtime (hard rule). The model ships *inside the app*
/// (see `project.yml`'s bundling script + `scripts/fetch-model.sh`), so
/// readiness is decided synchronously from the device's capability and whether
/// the bundled (or, in dev, store-resident) file is present.
enum ModelReadiness: Sendable, Equatable {
    /// Ready to load, at this on-disk URL (bundled inside the app, or installed
    /// in the model store during development).
    case ready(URL)
    /// The device can't run any deliverable quant; carries a user-facing reason.
    case unsupported(reason: String)
    /// The device *could* run the model, but its file isn't present — i.e. the
    /// build didn't bundle the weights. A packaging error, not a user state: a
    /// correct release always ships the file.
    case missing(spec: LLMModelSpec)
}

/// Resolves whether the on-device model is ready to use — with **no network**.
///
/// The weights are bundled into the app (the app never downloads them at
/// runtime; that is a hard product rule). This type is therefore a pure,
/// synchronous resolver over two inputs: the device-capability gate (A-25 — can
/// this device run a deliverable quant at all?) and the ``ModelStore`` (is the
/// chosen quant's file present and the right size?). It does not load the model
/// — that's the engine's job once a runtime binary exists.
struct ModelProvisioner: Sendable {
    let catalog: LLMModelCatalog
    let gate: DeviceCapabilityGate
    let store: ModelStore

    init(
        catalog: LLMModelCatalog = .v1,
        gate: DeviceCapabilityGate? = nil,
        store: ModelStore
    ) {
        self.catalog = catalog
        self.gate = gate ?? DeviceCapabilityGate(catalog: catalog)
        self.store = store
    }

    /// The spec this device should use, or nil if unsupported.
    func plannedSpec(for capability: DeviceCapability = .current) -> LLMModelSpec? {
        if case let .supported(spec) = gate.evaluate(capability) { return spec }
        return nil
    }

    /// True when the device's planned model is present and the right size.
    func isReady(for capability: DeviceCapability = .current) -> Bool {
        guard let spec = plannedSpec(for: capability) else { return false }
        return store.isInstalled(spec)
    }

    /// Resolve readiness now. Synchronous and side-effect-free beyond a
    /// file-size stat — no async, no I/O, and crucially no download.
    func resolve(for capability: DeviceCapability = .current) -> ModelReadiness {
        switch gate.evaluate(capability) {
        case let .unsupported(reason):
            return .unsupported(reason: reason)
        case let .supported(spec):
            guard let url = store.installedURL(for: spec) else {
                return .missing(spec: spec)
            }
            return .ready(url)
        }
    }
}
