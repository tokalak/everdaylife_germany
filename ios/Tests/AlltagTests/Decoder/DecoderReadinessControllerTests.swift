import XCTest
@testable import Alltag

/// The first-run readiness state machine (P3-00): consent gate, device gate,
/// download→verify→ready, and the unsupported/failure branches — all with a fake
/// downloader, no device.
@MainActor
final class DecoderReadinessControllerTests: XCTestCase {
    private let payload = Data("a tiny fake model file".utf8)

    /// Spin the run loop until `predicate` holds or we give up, so we can await
    /// the controller's internal provisioning Task without exposing it.
    private func wait(
        for predicate: @escaping () -> Bool, timeout: TimeInterval = 2
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !predicate() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    func testReadyImmediatelyWhenModelAlreadyInstalled() throws {
        let provisioner = try DecoderReadinessFactory.provisioner(matching: payload)
        // Pre-install the primary spec by writing the matching bytes into place.
        try payload.write(to: provisioner.store.url(for: provisioner.catalog.primary))

        let controller = DecoderReadinessController(
            provisioner: provisioner,
            capability: DecoderReadinessFactory.capableDevice,
            defaults: DecoderReadinessFactory.defaults())

        XCTAssertEqual(controller.readiness, .ready)
        XCTAssertTrue(controller.isReady)
    }

    func testStartRequestsConsentWhenTermsNotAccepted() throws {
        let controller = try makeController()
        controller.start()
        XCTAssertEqual(controller.readiness, .needsConsent)
        XCTAssertFalse(controller.hasAcceptedTerms)
    }

    func testAcceptingTermsDownloadsThroughToReady() async throws {
        let defaults = DecoderReadinessFactory.defaults()
        let controller = try makeController(defaults: defaults)

        controller.start()
        XCTAssertEqual(controller.readiness, .needsConsent)

        controller.acceptTermsAndDownload()
        await wait(for: { controller.readiness == .ready })

        XCTAssertEqual(controller.readiness, .ready)
        XCTAssertTrue(controller.hasAcceptedTerms)
        XCTAssertTrue(defaults.bool(forKey: "alltag.gemmaTermsAccepted"))
    }

    func testStartSkipsConsentWhenAlreadyAccepted() async throws {
        let defaults = DecoderReadinessFactory.defaults()
        defaults.set(true, forKey: "alltag.gemmaTermsAccepted")
        let controller = try makeController(defaults: defaults)

        controller.start()
        await wait(for: { controller.readiness == .ready })

        XCTAssertEqual(controller.readiness, .ready)
    }

    func testUnsupportedDeviceIsReported() throws {
        let controller = try makeController(capability: DecoderReadinessFactory.incapableDevice)
        controller.start()
        if case .unsupported = controller.readiness {
            // expected
        } else {
            XCTFail("expected .unsupported, got \(controller.readiness)")
        }
    }

    func testDownloadFailureSurfacesFailedState() async throws {
        let provisioner = try DecoderReadinessFactory.failingProvisioner()
        let controller = DecoderReadinessController(
            provisioner: provisioner,
            capability: DecoderReadinessFactory.capableDevice,
            defaults: DecoderReadinessFactory.defaults())

        controller.acceptTermsAndDownload()
        await wait(for: {
            if case .failed = controller.readiness { return true }
            return false
        })

        if case .failed = controller.readiness {
            // expected
        } else {
            XCTFail("expected .failed, got \(controller.readiness)")
        }
    }

    // MARK: - Helpers

    private func makeController(
        capability: DeviceCapability = DecoderReadinessFactory.capableDevice,
        defaults: UserDefaults? = nil
    ) throws -> DecoderReadinessController {
        DecoderReadinessController(
            provisioner: try DecoderReadinessFactory.provisioner(matching: payload),
            capability: capability,
            defaults: defaults ?? DecoderReadinessFactory.defaults())
    }
}
