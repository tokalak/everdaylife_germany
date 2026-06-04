import Foundation

/// A step in bringing the on-device model from "nothing" to "ready" (P3-00).
///
/// Emitted as a stream so the readiness UI can show device-check → download
/// progress → verify → done, or stop early on an unsupported device.
enum ProvisioningEvent: Sendable, Equatable {
    case checkingDevice
    /// Device can't run any deliverable quant; carries the user-facing reason.
    case unsupportedDevice(reason: String)
    /// The right model for this device is already on disk and valid.
    case alreadyInstalled(URL)
    /// Downloading the chosen spec; fraction is `nil` when length is unknown.
    case downloading(fraction: Double?)
    case verifying
    /// Installed and ready to load.
    case ready(URL)
}

/// Orchestrates first-run model readiness end to end (A-22…A-26, P3-00).
///
/// Pipeline: **capability gate → already-installed? → download → verify →
/// install → ready**. Each model-mutating dependency is injected behind a
/// protocol/value type, so the whole flow round-trips in a unit test with a fake
/// downloader writing known bytes — no network, no 3 GB, no device. That
/// round-trip test is the concrete deliverable the P0-07 spike asks of the
/// non-device code.
///
/// The provisioner never loads the model itself — that's the engine's job once a
/// runtime binary exists. It only guarantees a verified file is on disk.
struct ModelProvisioner: Sendable {
    let catalog: LLMModelCatalog
    let gate: DeviceCapabilityGate
    let store: ModelStore
    let downloader: any ModelDownloading
    let verifier: ModelVerifier

    init(
        catalog: LLMModelCatalog = .v1,
        gate: DeviceCapabilityGate? = nil,
        store: ModelStore,
        downloader: any ModelDownloading,
        verifier: ModelVerifier = ModelVerifier()
    ) {
        self.catalog = catalog
        self.gate = gate ?? DeviceCapabilityGate(catalog: catalog)
        self.store = store
        self.downloader = downloader
        self.verifier = verifier
    }

    /// The spec this device should use, or nil if unsupported. Lets callers
    /// (Settings, Decode-entry gate) ask without kicking off a download.
    func plannedSpec(for capability: DeviceCapability = .current) -> LLMModelSpec? {
        if case let .supported(spec) = gate.evaluate(capability) { return spec }
        return nil
    }

    /// True when the device's planned model is present and the right size.
    func isReady(for capability: DeviceCapability = .current) -> Bool {
        guard let spec = plannedSpec(for: capability) else { return false }
        return store.isInstalled(spec)
    }

    func provision(
        for capability: DeviceCapability = .current
    ) -> AsyncThrowingStream<ProvisioningEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await run(capability: capability, into: continuation)
                } catch is CancellationError {
                    continuation.finish(throwing: LLMError.cancelled)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(
        capability: DeviceCapability,
        into continuation: AsyncThrowingStream<ProvisioningEvent, Error>.Continuation
    ) async throws {
        continuation.yield(.checkingDevice)

        let spec: LLMModelSpec
        switch gate.evaluate(capability) {
        case let .unsupported(reason):
            continuation.yield(.unsupportedDevice(reason: reason))
            continuation.finish()
            return
        case let .supported(supportedSpec):
            spec = supportedSpec
        }

        if store.isInstalled(spec) {
            continuation.yield(.alreadyInstalled(store.url(for: spec)))
            continuation.finish()
            return
        }

        var downloadedURL: URL?
        for try await event in downloader.download(spec) {
            try Task.checkCancellation()
            switch event {
            case let .progress(fraction):
                continuation.yield(.downloading(fraction: fraction))
            case let .completed(url):
                downloadedURL = url
            }
        }
        guard let downloadedURL else {
            throw LLMError.modelNotLoaded
        }

        continuation.yield(.verifying)
        do {
            try verifier.verify(fileAt: downloadedURL, against: spec)
        } catch {
            // Don't leave a bad partial file behind.
            try? FileManager.default.removeItem(at: downloadedURL)
            throw error
        }

        let installed = try store.install(from: downloadedURL, as: spec)
        continuation.yield(.ready(installed))
        continuation.finish()
    }
}
