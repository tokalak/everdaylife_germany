import XCTest
@testable import Alltag

/// P0-07 / OQ-14: the catalog carries the shippable llama.cpp candidates and the
/// recorded runtime decision defaults to Candidate A.
final class LLMModelCatalogTests: XCTestCase {
    func testPrimaryIsGemma4E2BQ4OnLlamaCpp() {
        let primary = LLMModelCatalog.v1.primary
        XCTAssertEqual(primary.runtime, .llamaCpp)
        XCTAssertEqual(primary.quant, .q4_K_M)
        XCTAssertTrue(primary.fileName.hasSuffix(".gguf"))
        XCTAssertEqual(primary.expectedByteCount, ModelQuant.q4_K_M.approximateByteCount)
    }

    func testDeliverableSpecsAreLlamaCppOnly() {
        // Candidate B (LiteRT-LM) is recorded for the spike but not deliverable.
        XCTAssertEqual(LLMModelCatalog.v1.deliverable.count, 2)
        XCTAssertTrue(LLMModelCatalog.v1.deliverable.allSatisfy { $0.runtime == .llamaCpp })
        XCTAssertEqual(LLMModelCatalog.v1.candidateB.runtime, .liteRTLM)
    }

    func testLowMemoryFallbackIsSmallerThanPrimary() {
        let catalog = LLMModelCatalog.v1
        XCTAssertEqual(catalog.lowMemoryFallback.quant, .q3_K_M)
        XCTAssertLessThan(
            catalog.lowMemoryFallback.expectedByteCount,
            catalog.primary.expectedByteCount)
        XCTAssertLessThan(
            ModelQuant.q3_K_M.minimumDeviceMemory,
            ModelQuant.q4_K_M.minimumDeviceMemory)
    }

    func testSpecLookupByQuant() {
        XCTAssertEqual(LLMModelCatalog.v1.spec(for: .q4_K_M)?.quant, .q4_K_M)
        XCTAssertEqual(LLMModelCatalog.v1.spec(for: .q3_K_M)?.quant, .q3_K_M)
    }

    func testContextWindowCappedWellBelow128K() {
        // A-26: cap KV-cache RAM — letters are short.
        XCTAssertLessThanOrEqual(LLMModelCatalog.v1.primary.contextWindowCap, 16_384)
    }

    func testRuntimeDecisionDefaultsToLlamaCppPendingBenchmark() {
        XCTAssertEqual(RuntimeDecision.current.chosen, .llamaCpp)
        XCTAssertFalse(
            RuntimeDecision.current.benchmarkComplete,
            "on-device benchmark is a manual step; keep this false until run")
        XCTAssertFalse(RuntimeDecision.current.rationale.isEmpty)
    }
}
