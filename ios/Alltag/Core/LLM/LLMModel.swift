import Foundation

/// Quantisation level of a Gemma 4 E2B weight file.
///
/// Smaller quants trade a little quality for a smaller download and lower RAM,
/// which is how we reach older/lower-RAM iPhones (A-25, OQ-8/OQ-11). The byte
/// sizes and RAM floors are **approximations isolated here as versioned content**
/// (X-06) — they are tuned by the A-28 eval harness and the supported-device
/// matrix, never hard-coded into views.
enum ModelQuant: String, Sendable, CaseIterable, Codable {
    /// Default: Unsloth dynamic **QAT** 4-bit (`UD-Q4_K_XL`, 2.62 GB). QAT
    /// (quantization-aware training) recovers most of the accuracy lost to
    /// quantisation, so this is both *smaller* and *higher quality* than the
    /// old post-training `Q4_K_M`. Unsloth ships only this one precision —
    /// higher quants degrade rather than improve QAT accuracy.
    case q4_K_XL
    /// Mobile-mixture QAT 2-bit fallback (`UD-Q2_K_XL`, ≈2.19 GB) for
    /// ~4 GB-RAM devices.
    case q2_K_XL

    /// Suffix used in the GGUF filename (`…-<suffix>.gguf`).
    var fileSuffix: String {
        switch self {
        case .q4_K_XL: "UD-Q4_K_XL"
        case .q2_K_XL: "UD-Q2_K_XL"
        }
    }

    /// Exact on-disk size of the weight file, in bytes (a fast integrity gate
    /// before hashing — ``ModelVerifier`` requires an exact match).
    var approximateByteCount: Int64 {
        switch self {
        case .q4_K_XL: 2_620_368_960   // 2.62 GB (unsloth/gemma-4-E2B-it-qat-GGUF)
        case .q2_K_XL: 2_186_184_768   // ≈2.19 GB (mobile mixture)
        }
    }

    /// Minimum device physical RAM to run this quant with a small KV cache
    /// without thrashing (A-25/A-26). Weights must be resident plus headroom for
    /// the OS, the app, and a capped context window.
    var minimumDeviceMemory: UInt64 {
        switch self {
        case .q4_K_XL: 6 * 1_024 * 1_024 * 1_024   // ~6 GB-class devices
        case .q2_K_XL: 4 * 1_024 * 1_024 * 1_024   // ~4 GB-class devices
        }
    }
}

/// Everything needed to fetch, verify, and locate one on-device model file.
///
/// A spec is *data*, not behaviour: it describes a downloadable artifact so that
/// ``ModelStore`` knows where to put it, ``ModelDownloading`` knows where to get
/// it, and ``ModelVerifier`` knows how to validate it (A-22).
struct LLMModelSpec: Sendable, Equatable, Identifiable, Codable {
    /// Stable identifier, e.g. `gemma-4-e2b-it-q4_k_m`.
    let id: String
    /// Shown in readiness/Settings UI.
    let displayName: String
    /// Runtime that consumes this file (drives the engine choice).
    let runtime: LLMRuntime
    /// Quant level (nil for non-GGUF runtimes such as LiteRT-LM).
    let quant: ModelQuant?
    /// On-disk filename, e.g. `gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf`.
    let fileName: String
    /// Where to download it from (HF direct or a CDN mirror — OQ-10).
    let sourceURL: URL
    /// Expected size in bytes; a fast integrity check before hashing (A-22).
    let expectedByteCount: Int64
    /// Expected SHA-256 of the file, lowercase hex. `nil` until pinned for a
    /// release — size is still checked, and the verifier requires this before a
    /// build ships (gated by tests / release checklist).
    let sha256: String?
    /// KV-cache context window cap, well below Gemma's 128K to bound RAM
    /// (A-26) — Behörden letters are short.
    let contextWindowCap: Int

    /// Minimum device RAM to run this spec (from its quant, or a runtime floor).
    var minimumDeviceMemory: UInt64 {
        quant?.minimumDeviceMemory ?? (4 * 1_024 * 1_024 * 1_024)
    }
}

/// The set of models the app knows how to provision, plus the rules for picking
/// one for a device.
///
/// This is the single versioned source for model URLs/sizes/quants (X-06). It
/// carries both llama.cpp candidates we actually ship (primary + low-memory
/// fallback) and a record of Candidate B (LiteRT-LM) kept for the OQ-14 spike.
struct LLMModelCatalog: Sendable, Equatable {
    /// Candidate A, default: Gemma 4 E2B **QAT** GGUF `UD-Q4_K_XL` on llama.cpp.
    let primary: LLMModelSpec
    /// Smaller quant for low-RAM devices (still llama.cpp/GGUF).
    let lowMemoryFallback: LLMModelSpec
    /// Candidate B: the LiteRT-LM `.litertlm` artifact — recorded for the spike,
    /// not shipped unless the benchmark flips ``RuntimeDecision``.
    let candidateB: LLMModelSpec

    /// Specs that can actually be served to a device, heaviest (best) first —
    /// the capability gate walks this to pick the richest quant that fits.
    var deliverable: [LLMModelSpec] { [primary, lowMemoryFallback] }

    /// The spec for a given quant, if the catalog carries it.
    func spec(for quant: ModelQuant) -> LLMModelSpec? {
        deliverable.first { $0.quant == quant }
    }

    /// The v1 catalog. URLs point at `unsloth/gemma-4-E2B-it-qat-GGUF` (the
    /// QAT build; OQ-10 may later swap in a CDN mirror); checksums are pinned
    /// at release time.
    static let v1 = LLMModelCatalog(
        primary: LLMModelSpec(
            id: "gemma-4-e2b-it-qat-q4_k_xl",
            displayName: "Gemma 4 E2B · QAT Q4_K_XL",
            runtime: .llamaCpp,
            quant: .q4_K_XL,
            fileName: "gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf",
            sourceURL: URL(
                string: "https://huggingface.co/unsloth/gemma-4-E2B-it-qat-GGUF/resolve/main/gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf")!,
            expectedByteCount: ModelQuant.q4_K_XL.approximateByteCount,
            sha256: nil,
            contextWindowCap: 8_192),
        lowMemoryFallback: LLMModelSpec(
            id: "gemma-4-e2b-it-qat-q2_k_xl",
            displayName: "Gemma 4 E2B · QAT Q2_K_XL (low memory)",
            runtime: .llamaCpp,
            quant: .q2_K_XL,
            fileName: "gemma-4-E2B-it-qat-UD-Q2_K_XL.gguf",
            sourceURL: URL(
                string: "https://huggingface.co/unsloth/gemma-4-E2B-it-qat-GGUF/resolve/main/gemma-4-E2B-it-qat-UD-Q2_K_XL.gguf")!,
            expectedByteCount: ModelQuant.q2_K_XL.approximateByteCount,
            sha256: nil,
            contextWindowCap: 8_192),
        candidateB: LLMModelSpec(
            id: "gemma-4-e2b-it-litertlm",
            displayName: "Gemma 4 E2B · LiteRT-LM",
            runtime: .liteRTLM,
            quant: nil,
            fileName: "gemma-4-E2B-it.litertlm",
            sourceURL: URL(
                string: "https://huggingface.co/google/gemma-4-E2B-it-litert-preview/resolve/main/gemma-4-E2B-it.litertlm")!,
            expectedByteCount: 2_590_000_000,
            sha256: nil,
            contextWindowCap: 8_192))
}
