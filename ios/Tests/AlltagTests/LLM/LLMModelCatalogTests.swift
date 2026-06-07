import XCTest
@testable import Alltag

/// P0-07 / OQ-14: the catalog carries the shippable llama.cpp candidates and the
/// recorded runtime decision defaults to Candidate A.
final class LLMModelCatalogTests: XCTestCase {
    func testPrimaryIsQwen3_5_0_8BOnLlamaCpp() {
        let primary = LLMModelCatalog.v1.primary
        XCTAssertEqual(primary.runtime, .llamaCpp)
        XCTAssertEqual(primary.quant, .q4_K_M)
        XCTAssertTrue(primary.fileName.hasSuffix(".gguf"))
        XCTAssertTrue(primary.fileName.contains("Qwen"))
        XCTAssertEqual(primary.expectedByteCount, ModelQuant.q4_K_M.approximateByteCount)
    }

    func testDeliverableIsTheSingleQwenModelOnLlamaCpp() {
        // Qwen3.5-0.8B is small enough to be the one shipping model; Candidate B
        // (LiteRT-LM) is recorded for the spike but not deliverable.
        XCTAssertEqual(LLMModelCatalog.v1.deliverable.count, 1)
        XCTAssertTrue(LLMModelCatalog.v1.deliverable.allSatisfy { $0.runtime == .llamaCpp })
        XCTAssertEqual(LLMModelCatalog.v1.candidateB.runtime, .liteRTLM)
    }

    func testLowMemoryFallbackMirrorsPrimary() {
        // No separate low-memory build: the model already fits the lowest
        // supported device, so the fallback slot points at the same spec.
        let catalog = LLMModelCatalog.v1
        XCTAssertEqual(catalog.lowMemoryFallback, catalog.primary)
    }

    func testDefaultQuantIsQwenQ4KM() {
        XCTAssertEqual(LLMModelCatalog.v1.defaultQuant, .q4_K_M)
        XCTAssertNotNil(
            LLMModelCatalog.v1.spec(for: LLMModelCatalog.v1.defaultQuant),
            "default quant must be a deliverable spec")
    }

    func testSpecLookupByQuant() {
        XCTAssertEqual(LLMModelCatalog.v1.spec(for: .q4_K_M)?.quant, .q4_K_M)
        // The legacy Gemma quants are no longer deliverable.
        XCTAssertNil(LLMModelCatalog.v1.spec(for: .q4_K_XL))
        XCTAssertNil(LLMModelCatalog.v1.spec(for: .q2_K_XL))
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
