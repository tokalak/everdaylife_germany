import Foundation
import Observation

/// Where the on-device model stands from the Decoder's point of view (P3-00).
///
/// The model ships **bundled inside the app** — the app never downloads it at
/// runtime (hard rule) — so this is resolved synchronously and is almost always
/// ``ready``. The readiness view renders exactly one of these; the Decode entry
/// point is gated on ``ready``.
enum DecoderReadiness: Equatable, Sendable {
    /// Model present and valid — the Decoder is usable, fully offline.
    case ready
    /// This device can't run the Decoder; carries a user-facing reason (A-25).
    case unsupported(reason: String)
    /// The device could run it, but the weights weren't bundled into this build
    /// (a packaging error — a shipped build always includes them).
    case unavailable
}

/// Drives model readiness for the Decoder (P3-00).
///
/// Sits between the readiness UI and the ``ModelProvisioner`` (A-25). Because the
/// weights are bundled in the app and never downloaded, this is a thin,
/// synchronous translation of the provisioner's verdict into a single observable
/// ``DecoderReadiness`` the view binds to — no consent gate, no download
/// progress, no async work. Everything is injected so it unit-tests with no
/// device.
@MainActor
@Observable
final class DecoderReadinessController {
    @ObservationIgnored private let provisioner: ModelProvisioner
    @ObservationIgnored private let capability: DeviceCapability

    private(set) var readiness: DecoderReadiness

    init(
        provisioner: ModelProvisioner,
        capability: DeviceCapability = .current
    ) {
        self.provisioner = provisioner
        self.capability = capability
        self.readiness = Self.map(provisioner.resolve(for: capability))
    }

    var isReady: Bool { readiness == .ready }

    /// Re-evaluate readiness (e.g. when the readiness screen appears). Pure and
    /// synchronous — there is nothing to download or await.
    func start() {
        readiness = Self.map(provisioner.resolve(for: capability))
    }

    private static func map(_ outcome: ModelReadiness) -> DecoderReadiness {
        switch outcome {
        case .ready: .ready
        case let .unsupported(reason): .unsupported(reason: reason)
        case .missing: .unavailable
        }
    }
}
