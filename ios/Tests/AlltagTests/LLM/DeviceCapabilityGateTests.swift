import XCTest
@testable import Alltag

/// A-25: the gate picks the catalog's preferred default quant when it fits, or
/// fails the device cleanly when nothing does.
final class DeviceCapabilityGateTests: XCTestCase {
    private let gate = DeviceCapabilityGate(catalog: .v1)
    private let gb: UInt64 = 1_024 * 1_024 * 1_024

    func testHighMemoryDeviceStillGetsDefaultQuant() {
        // Policy over capability: an 8 GB device *could* run q4_K_XL, but the
        // catalog defaults to q2_K_XL, so that's what it gets.
        let support = gate.evaluate(DeviceCapability(physicalMemory: 8 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("8 GB device should be supported")
        }
        XCTAssertEqual(spec.quant, LLMModelCatalog.v1.defaultQuant)
        XCTAssertEqual(spec.quant, .q2_K_XL)
    }

    func testMidMemoryDeviceGetsDefaultQuant() {
        // 4 GB clears the default (q2_K_XL) floor.
        let support = gate.evaluate(DeviceCapability(physicalMemory: 4 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("4 GB device should be supported")
        }
        XCTAssertEqual(spec.quant, .q2_K_XL)
    }

    func testLowMemoryDeviceIsUnsupportedWithReason() {
        let support = gate.evaluate(DeviceCapability(physicalMemory: 2 * gb))
        guard case let .unsupported(reason) = support else {
            return XCTFail("2 GB device should be unsupported")
        }
        XCTAssertFalse(reason.isEmpty)
    }

    func testExactDefaultFloorIsInclusive() {
        let support = gate.evaluate(
            DeviceCapability(physicalMemory: ModelQuant.q2_K_XL.minimumDeviceMemory))
        guard case let .supported(spec) = support else {
            return XCTFail("device exactly at the default quant's floor should qualify")
        }
        XCTAssertEqual(spec.quant, .q2_K_XL)
    }

    /// Graceful degradation: if the configured default doesn't fit, the gate
    /// steps down to the heaviest quant that still does. (Locks the fallback
    /// branch, which the q2_K_XL default never exercises since it's the lowest.)
    func testFallsBackWhenDefaultQuantDoesNotFit() {
        var catalog = LLMModelCatalog.v1
        catalog = LLMModelCatalog(
            primary: catalog.primary,
            lowMemoryFallback: catalog.lowMemoryFallback,
            candidateB: catalog.candidateB,
            defaultQuant: .q4_K_XL)
        let gate = DeviceCapabilityGate(catalog: catalog)

        // 4 GB can't run the (now) default q4_K_XL (6 GB floor) → falls back.
        let support = gate.evaluate(DeviceCapability(physicalMemory: 4 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("4 GB device should fall back, not be rejected")
        }
        XCTAssertEqual(spec.quant, .q2_K_XL)
    }
}
