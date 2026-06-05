import Foundation
import Observation

/// Where the on-device model stands from the Decoder's point of view (P3-00).
///
/// The readiness view renders exactly one of these; the Decode entry point is
/// gated on `.ready`.
enum DecoderReadiness: Equatable, Sendable {
    /// Nothing started yet (and the model isn't already present).
    case idle
    /// The Gemma terms must be accepted before the first ~3 GB download (A-24).
    case needsConsent
    /// Confirming the device can run a deliverable quant (A-25).
    case checkingDevice
    /// Downloading the model; `fraction` is `nil` while length is unknown.
    case downloading(fraction: Double?)
    /// Verifying the downloaded file (size + checksum).
    case verifying
    /// Model present and valid — the Decoder is usable, fully offline.
    case ready
    /// This device can't run the Decoder; carries a user-facing reason (A-25).
    case unsupported(reason: String)
    /// Provisioning failed (network, disk, checksum); carries a short message.
    case failed(message: String)
}

/// Drives first-run model readiness for the Decoder (P3-00).
///
/// Sits between the readiness UI and the ``ModelProvisioner`` (A-22…A-26),
/// translating the provisioning event stream into a single observable
/// ``DecoderReadiness`` the view binds to, and enforcing the **Gemma terms
/// acceptance gate** (A-24) before the large download ever starts. The consent
/// flag is persisted, so the user accepts once.
///
/// Everything is injected (provisioner, device capability, defaults), so the
/// whole flow — consent → device check → download → verify → ready, plus the
/// unsupported and failure branches — unit-tests with a fake downloader and no
/// device.
@MainActor
@Observable
final class DecoderReadinessController {
    private static let consentKey = "alltag.gemmaTermsAccepted"

    @ObservationIgnored private let provisioner: ModelProvisioner
    @ObservationIgnored private let capability: DeviceCapability
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var task: Task<Void, Never>?

    private(set) var readiness: DecoderReadiness

    init(
        provisioner: ModelProvisioner,
        capability: DeviceCapability = .current,
        defaults: UserDefaults = .standard
    ) {
        self.provisioner = provisioner
        self.capability = capability
        self.defaults = defaults
        // If a valid model is already installed, the Decoder is ready with no
        // ceremony on launch.
        self.readiness = provisioner.isReady(for: capability) ? .ready : .idle
    }

    var isReady: Bool { readiness == .ready }

    /// Whether the user has already accepted the Gemma terms (A-24).
    var hasAcceptedTerms: Bool { defaults.bool(forKey: Self.consentKey) }

    /// Decide the first screen to show when the user opens Decode: ready,
    /// unsupported, the consent gate, or straight into provisioning if terms were
    /// accepted on a prior run but the download didn't finish.
    func start() {
        switch provisioner.gate.evaluate(capability) {
        case let .unsupported(reason):
            readiness = .unsupported(reason: reason)
        case .supported:
            if provisioner.isReady(for: capability) {
                readiness = .ready
            } else if hasAcceptedTerms {
                beginProvision()
            } else {
                readiness = .needsConsent
            }
        }
    }

    /// User accepted the Gemma terms — persist it and start the download (A-24).
    func acceptTermsAndDownload() {
        defaults.set(true, forKey: Self.consentKey)
        beginProvision()
    }

    /// Retry after a failure — terms are already accepted at this point.
    func retry() {
        beginProvision()
    }

    /// Cancel an in-flight download and return to a resumable idle state.
    func cancel() {
        task?.cancel()
        task = nil
        readiness = .idle
    }

    private func beginProvision() {
        task?.cancel()
        readiness = .checkingDevice
        task = Task { @MainActor [provisioner, capability] in
            do {
                for try await event in provisioner.provision(for: capability) {
                    self.apply(event)
                }
            } catch is CancellationError {
                // User-initiated cancel — leave the state set by cancel().
            } catch let error as LLMError where error == .cancelled {
                // Same as above, surfaced through the provisioning stream.
            } catch {
                self.readiness = .failed(
                    message: "The download couldn't finish. Check your connection "
                        + "and try again.")
            }
        }
    }

    private func apply(_ event: ProvisioningEvent) {
        switch event {
        case .checkingDevice:
            readiness = .checkingDevice
        case let .unsupportedDevice(reason):
            readiness = .unsupported(reason: reason)
        case .alreadyInstalled:
            readiness = .ready
        case let .downloading(fraction):
            readiness = .downloading(fraction: fraction)
        case .verifying:
            readiness = .verifying
        case .ready:
            readiness = .ready
        }
    }
}
