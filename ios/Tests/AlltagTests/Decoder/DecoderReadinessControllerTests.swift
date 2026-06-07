import XCTest
@testable import Alltag

/// The readiness state machine (P3-00) with the model **bundled in the app** —
/// no download, no consent, no async. It resolves synchronously: ready when the
/// model is installed/bundled, unsupported on a weak device, and unavailable
/// when the build didn't ship the weights.
@MainActor
final class DecoderReadinessControllerTests: XCTestCase {
    private let payload = Data("a tiny fake model file".utf8)

    func testReadyWhenModelInstalled() throws {
        let provisioner = try DecoderReadinessFactory.readyProvisioner(matching: payload)
        let controller = DecoderReadinessController(
            provisioner: provisioner, capability: DecoderReadinessFactory.capableDevice)

        XCTAssertEqual(controller.readiness, .ready)
        XCTAssertTrue(controller.isReady)
    }

    func testStartIsIdempotentWhenReady() throws {
        let provisioner = try DecoderReadinessFactory.readyProvisioner(matching: payload)
        let controller = DecoderReadinessController(
            provisioner: provisioner, capability: DecoderReadinessFactory.capableDevice)

        controller.start()
        XCTAssertEqual(controller.readiness, .ready)
    }

    func testUnsupportedDeviceIsReported() throws {
        let provisioner = try DecoderReadinessFactory.readyProvisioner(matching: payload)
        let controller = DecoderReadinessController(
            provisioner: provisioner, capability: DecoderReadinessFactory.incapableDevice)

        if case .unsupported = controller.readiness {
            // expected
        } else {
            XCTFail("expected .unsupported, got \(controller.readiness)")
        }
    }

    func testUnavailableWhenModelNotBundled() throws {
        // Capable device, but nothing installed/bundled — a packaging error.
        let provisioner = try DecoderReadinessFactory.provisioner(matching: payload)
        let controller = DecoderReadinessController(
            provisioner: provisioner, capability: DecoderReadinessFactory.capableDevice)

        XCTAssertEqual(controller.readiness, .unavailable)
        XCTAssertFalse(controller.isReady)
    }
}
