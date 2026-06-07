import XCTest
@testable import Alltag

/// A-25: the gate picks the catalog's preferred default quant when it fits, or
/// fails the device cleanly when nothing does.
final class DeviceCapabilityGateTests: XCTestCase {
    private let gate = DeviceCapabilityGate(catalog: .v1)
    private let gb: UInt64 = 1_024 * 1_024 * 1_024

    func testHighMemoryDeviceGetsDefaultQuant() {
        // An 8 GB device runs the shipping model (Qwen3.5-0.8B, q4_K_M).
        let support = gate.evaluate(DeviceCapability(physicalMemory: 8 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("8 GB device should be supported")
        }
        XCTAssertEqual(spec.quant, LLMModelCatalog.v1.defaultQuant)
        XCTAssertEqual(spec.quant, .q4_K_M)
    }

    func testMidMemoryDeviceGetsDefaultQuant() {
        // 2 GB comfortably clears the q4_K_M floor (1.5 GiB).
        let support = gate.evaluate(DeviceCapability(physicalMemory: 2 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("2 GB device should be supported")
        }
        XCTAssertEqual(spec.quant, .q4_K_M)
    }

    func testLowMemoryDeviceIsUnsupportedWithReason() {
        // 1 GB is below the q4_K_M floor (1.5 GiB).
        let support = gate.evaluate(DeviceCapability(physicalMemory: 1 * gb))
        guard case let .unsupported(reason) = support else {
            return XCTFail("1 GB device should be unsupported")
        }
        XCTAssertFalse(reason.isEmpty)
    }

    func testExactDefaultFloorIsInclusive() {
        let support = gate.evaluate(
            DeviceCapability(physicalMemory: ModelQuant.q4_K_M.minimumDeviceMemory))
        guard case let .supported(spec) = support else {
            return XCTFail("device exactly at the default quant's floor should qualify")
        }
        XCTAssertEqual(spec.quant, .q4_K_M)
    }

    /// Graceful degradation: if the configured default quant isn't among the
    /// deliverable specs, the gate still serves the affordable spec rather than
    /// rejecting a capable device (the `?? affordable.first` branch).
    func testServesDeliverableWhenDefaultQuantNotDeliverable() {
        let catalog = LLMModelCatalog(
            primary: LLMModelCatalog.v1.primary,
            lowMemoryFallback: LLMModelCatalog.v1.lowMemoryFallback,
            candidateB: LLMModelCatalog.v1.candidateB,
            defaultQuant: .q4_K_XL)  // not a deliverable quant
        let gate = DeviceCapabilityGate(catalog: catalog)

        let support = gate.evaluate(DeviceCapability(physicalMemory: 8 * gb))
        guard case let .supported(spec) = support else {
            return XCTFail("capable device should be served the deliverable spec")
        }
        XCTAssertEqual(spec.quant, .q4_K_M)
    }
}
