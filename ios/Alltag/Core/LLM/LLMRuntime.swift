import Foundation

/// On-device inference runtimes evaluated for the Decoder (P0-07 / OQ-14).
///
/// Both candidates run the **same model generation (Gemma 4 E2B)** — only the
/// file format and engine differ:
/// - ``llamaCpp`` — GGUF weights on `llama.cpp` with the Metal backend. Gives
///   **GBNF-grammar-guaranteed JSON** (A-27), quant flexibility, and mature
///   iOS-Metal support, independent of Google's iOS release cadence.
/// - ``liteRTLM`` — `.litertlm` weights on LiteRT-LM (the Google AI Edge Gallery
///   runtime). Smaller on disk and MTP fast-decode, but Gemma-4-on-iOS is still
///   unproven in this snapshot (the gallery's iOS allowlist lists only 3n).
///
/// The concrete engine sits behind ``LLMEngine`` (A-21) so the choice stays
/// swappable; this enum is what the wrapper is parameterised on.
enum LLMRuntime: String, Sendable, CaseIterable, Codable {
    case llamaCpp
    case liteRTLM

    /// Human-readable name for diagnostics / Settings.
    var displayName: String {
        switch self {
        case .llamaCpp: "llama.cpp (GGUF · Metal)"
        case .liteRTLM: "LiteRT-LM (.litertlm)"
        }
    }

    /// The on-disk weight format this runtime consumes.
    var fileFormat: String {
        switch self {
        case .llamaCpp: "gguf"
        case .liteRTLM: "litertlm"
        }
    }
}

/// The recorded outcome of the P0-07 runtime spike (closes OQ-14's default).
///
/// The decision rule (IMPLEMENTATION_PLAN §4, P0-07) is: **default to Candidate A
/// (llama.cpp/GGUF)** for its GBNF-guaranteed structured output and proven iOS
/// Metal maturity, and **switch to Candidate B only if** an on-device benchmark
/// shows it runs well on iOS *and* delivers a materially better
/// quality+latency+size result.
///
/// That benchmark is an inherently manual, real-device task (loading a ~3 GB
/// model and measuring first-token latency / peak RAM cannot run in CI or the
/// Simulator). Until it concludes, the recorded default below stands, and the
/// `LLMEngine` seam keeps the verdict cheap to revise.
struct RuntimeDecision: Sendable, Equatable {
    let chosen: LLMRuntime
    /// Why ``chosen`` is the default, and what would change it.
    let rationale: String
    /// Set once the on-device benchmark has been run and recorded.
    let benchmarkComplete: Bool

    /// The standing decision for v1 (default per the P0-07 decision rule).
    static let current = RuntimeDecision(
        chosen: .llamaCpp,
        rationale: """
        Default per P0-07 decision rule: llama.cpp/GGUF gives GBNF-guaranteed \
        valid JSON for the Decoder schema (A-27), quant flexibility (q4_K_M with \
        a q3_K_M low-memory fallback), and mature iOS-Metal support independent \
        of Google's iOS release cadence. Candidate B (LiteRT-LM) remains a \
        swap-in candidate pending an on-device benchmark on the same German \
        Behörden letters (OQ-14); switch only if it runs well on iOS AND is \
        materially better on quality+latency+size.
        """,
        benchmarkComplete: false)
}
