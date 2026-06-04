import Foundation

/// A snapshot of the device's inference-relevant capability (A-25).
///
/// Today the binding constraint is physical RAM: the weights must stay resident
/// alongside the OS, the app, and a capped KV cache. Chip/Neural-Engine class
/// can be folded in later (it correlates with RAM on iPhones), so RAM is the one
/// signal here and is injectable for tests.
struct DeviceCapability: Sendable, Equatable {
    let physicalMemory: UInt64

    /// The real device's capability.
    static var current: DeviceCapability {
        DeviceCapability(physicalMemory: ProcessInfo.processInfo.physicalMemory)
    }
}

/// The gate's verdict for a device: either a recommended model spec, or a clear
/// reason it can't run the Decoder (so the UI degrades gracefully, never
/// crashes — A-25).
enum DeviceSupport: Sendable, Equatable {
    /// The device can run this spec (the richest quant that fits).
    case supported(LLMModelSpec)
    /// No deliverable quant fits; carries a user-facing explanation.
    case unsupported(reason: String)
}

/// Decides which model (if any) a device should download (A-25).
///
/// Walks the catalog's deliverable specs heaviest-first and returns the first
/// whose RAM floor the device meets — so a 6 GB phone gets `q4_K_M` and a 4 GB
/// phone the `q3_K_M` fallback (OQ-8). Below the lowest floor it returns
/// ``DeviceSupport/unsupported(reason:)`` rather than letting the Decoder OOM.
struct DeviceCapabilityGate: Sendable {
    let catalog: LLMModelCatalog

    init(catalog: LLMModelCatalog = .v1) {
        self.catalog = catalog
    }

    func evaluate(_ capability: DeviceCapability) -> DeviceSupport {
        let affordable = catalog.deliverable
            .sorted { $0.minimumDeviceMemory > $1.minimumDeviceMemory }
            .first { capability.physicalMemory >= $0.minimumDeviceMemory }

        if let affordable {
            return .supported(affordable)
        }
        let neededGB = lowestFloorGigabytes()
        return .unsupported(
            reason: "This device doesn't have enough memory to run the on-device "
                + "Decoder. About \(neededGB) GB of RAM is needed.")
    }

    private func lowestFloorGigabytes() -> Int {
        let floor = catalog.deliverable
            .map(\.minimumDeviceMemory)
            .min() ?? (4 * 1_024 * 1_024 * 1_024)
        return Int(floor / (1_024 * 1_024 * 1_024))
    }
}
