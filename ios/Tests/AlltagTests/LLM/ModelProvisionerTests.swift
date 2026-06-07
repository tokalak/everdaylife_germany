import XCTest
@testable import Alltag

/// Readiness resolution with **no network** (A-25): the model ships bundled in
/// the app, so the provisioner is a pure gate + store check — supported device
/// with the file present → `.ready`; weak device → `.unsupported`; supported
/// device with no bundled/installed file → `.missing` (a packaging error).
final class ModelProvisionerTests: XCTestCase {
    private let gb: UInt64 = 1_024 * 1_024 * 1_024
    private var store: ModelStore!

    override func setUpWithError() throws {
        store = try LLMTestFactory.temporaryStore()
    }

    /// A catalog whose single deliverable spec matches `payload`. defaultQuant
    /// matches the spec's quant so an 8 GB device picks it.
    private func catalog(matching payload: Data) -> LLMModelCatalog {
        let spec = LLMTestFactory.spec(matching: payload, id: "primary")
        return LLMModelCatalog(
            primary: spec, lowMemoryFallback: spec, candidateB: spec,
            defaultQuant: spec.quant ?? .q4_K_XL)
    }

    func testReadyWhenInstalled() throws {
        let payload = Data("a real-enough gemma file".utf8)
        let cat = catalog(matching: payload)
        try payload.write(to: store.url(for: cat.primary))
        let provisioner = ModelProvisioner(catalog: cat, store: store)

        let device = DeviceCapability(physicalMemory: 8 * gb)
        guard case let .ready(url) = provisioner.resolve(for: device) else {
            return XCTFail("installed model should resolve ready")
        }
        XCTAssertEqual(url, store.url(for: cat.primary))
        XCTAssertTrue(provisioner.isReady(for: device))
    }

    func testReadyFromBundledCopy() throws {
        let payload = Data("weights shipped in the app".utf8)
        let cat = catalog(matching: payload)
        // Weights "bundled" in the app (a temp file here), store otherwise empty.
        let bundled = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try payload.write(to: bundled)
        let bundledStore = try ModelStore(
            directory: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true),
            bundledModelURL: { _ in bundled })
        let provisioner = ModelProvisioner(catalog: cat, store: bundledStore)

        guard case let .ready(url) = provisioner.resolve(
            for: DeviceCapability(physicalMemory: 8 * gb)) else {
            return XCTFail("bundled model should resolve ready")
        }
        XCTAssertEqual(url, bundled, "should load straight from the bundled copy")
    }

    func testUnsupportedDeviceResolvesUnsupported() {
        let provisioner = ModelProvisioner(
            catalog: catalog(matching: Data("x".utf8)), store: store)
        let device = DeviceCapability(physicalMemory: 1 * gb)
        guard case .unsupported = provisioner.resolve(for: device) else {
            return XCTFail("low-RAM device should be unsupported")
        }
        XCTAssertFalse(provisioner.isReady(for: device))
    }

    func testMissingWhenSupportedButNotBundled() {
        let cat = catalog(matching: Data("absent".utf8))
        // Empty store, nothing bundled for this spec's filename.
        let provisioner = ModelProvisioner(catalog: cat, store: store)
        let device = DeviceCapability(physicalMemory: 8 * gb)
        guard case let .missing(spec) = provisioner.resolve(for: device) else {
            return XCTFail("supported device with no file should be .missing")
        }
        XCTAssertEqual(spec, cat.primary)
        XCTAssertFalse(provisioner.isReady(for: device))
    }
}
