import XCTest
@testable import Alltag

/// P0-07 / OQ-14: the catalog carries the shippable llama.cpp candidates and the
/// recorded runtime decision defaults to Candidate A.
final class LLMModelCatalogTests: XCTestCase {
    func testPrimaryIsGemma4E2BQATQ4OnLlamaCpp() {
        let primary = LLMModelCatalog.v1.primary
        XCTAssertEqual(primary.runtime, .llamaCpp)
        XCTAssertEqual(primary.quant, .q4_K_XL)
        XCTAssertTrue(primary.fileName.hasSuffix(".gguf"))
        XCTAssertTrue(primary.fileName.contains("qat"))
        XCTAssertEqual(primary.expectedByteCount, ModelQuant.q4_K_XL.approximateByteCount)
    }

    func testDeliverableSpecsAreLlamaCppOnly() {
        // Candidate B (LiteRT-LM) is recorded for the spike but not deliverable.
        XCTAssertEqual(LLMModelCatalog.v1.deliverable.count, 2)
        XCTAssertTrue(LLMModelCatalog.v1.deliverable.allSatisfy { $0.runtime == .llamaCpp })
        XCTAssertEqual(LLMModelCatalog.v1.candidateB.runtime, .liteRTLM)
    }

    func testLowMemoryFallbackIsSmallerThanPrimary() {
        let catalog = LLMModelCatalog.v1
        XCTAssertEqual(catalog.lowMemoryFallback.quant, .q2_K_XL)
        XCTAssertLessThan(
            catalog.lowMemoryFallback.expectedByteCount,
            catalog.primary.expectedByteCount)
        XCTAssertLessThan(
            ModelQuant.q2_K_XL.minimumDeviceMemory,
            ModelQuant.q4_K_XL.minimumDeviceMemory)
    }

    func testDefaultQuantIsQ2Trial() {
        // Trial (2026-06-06): the app defaults to the smaller/faster q2_K_XL
        // while we evaluate whether its quality suffices. Flip to .q4_K_XL to
        // restore quality-first selection.
        XCTAssertEqual(LLMModelCatalog.v1.defaultQuant, .q2_K_XL)
        XCTAssertNotNil(
            LLMModelCatalog.v1.spec(for: LLMModelCatalog.v1.defaultQuant),
            "default quant must be a deliverable spec")
    }

    func testSpecLookupByQuant() {
        XCTAssertEqual(LLMModelCatalog.v1.spec(for: .q4_K_XL)?.quant, .q4_K_XL)
        XCTAssertEqual(LLMModelCatalog.v1.spec(for: .q2_K_XL)?.quant, .q2_K_XL)
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
