import XCTest
@testable import Alltag

/// A-25: the gate picks the richest quant a device can run, or fails it cleanly.
final class DeviceCapabilityGateTests: XCTestCase {
    private let gate = DeviceCapabilityGate(catalog: .v1)
    private let gb: UInt64 = 1_024 * 1_024 * 1_024

    func testHighMemoryDeviceGetsFullQuant() {
        let support = gate.evaluate(DeviceCapability(physicalMemory: 8 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("8 GB device should be supported")
        }
        XCTAssertEqual(spec.quant, .q4_K_M)
    }

    func testMidMemoryDeviceGetsLowMemoryFallback() {
        // 4 GB clears q3_K_M's floor but not q4_K_M's (6 GB).
        let support = gate.evaluate(DeviceCapability(physicalMemory: 4 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("4 GB device should fall back, not be rejected")
        }
        XCTAssertEqual(spec.quant, .q3_K_M)
    }

    func testLowMemoryDeviceIsUnsupportedWithReason() {
        let support = gate.evaluate(DeviceCapability(physicalMemory: 2 * gb))
        guard case let .unsupported(reason) = support else {
            return XCTFail("2 GB device should be unsupported")
        }
        XCTAssertFalse(reason.isEmpty)
    }

    func testExactFloorIsInclusive() {
        let support = gate.evaluate(
            DeviceCapability(physicalMemory: ModelQuant.q4_K_M.minimumDeviceMemory))
        guard case let .supported(spec) = support else {
            return XCTFail("device exactly at the floor should qualify")
        }
        XCTAssertEqual(spec.quant, .q4_K_M)
    }
}
