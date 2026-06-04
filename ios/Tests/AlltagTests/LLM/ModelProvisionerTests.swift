import XCTest
@testable import Alltag

/// P0-07 round-trip (A-22…A-26): the central deliverable of the non-device part
/// of the spike — provision goes gate → download → verify → install → ready with
/// a fake downloader, and fails cleanly on unsupported devices / bad bytes.
final class ModelProvisionerTests: XCTestCase {
    private let gb: UInt64 = 1_024 * 1_024 * 1_024
    private var store: ModelStore!

    override func setUpWithError() throws {
        store = try LLMTestFactory.temporaryStore()
    }

    /// A catalog whose single deliverable spec matches `payload`, so the fake
    /// download verifies and installs.
    private func catalog(matching payload: Data) -> LLMModelCatalog {
        let spec = LLMTestFactory.spec(matching: payload, id: "primary")
        return LLMModelCatalog(
            primary: spec, lowMemoryFallback: spec, candidateB: spec)
    }

    private func collect(
        _ stream: AsyncThrowingStream<ProvisioningEvent, Error>
    ) async throws -> [ProvisioningEvent] {
        var events: [ProvisioningEvent] = []
        for try await event in stream { events.append(event) }
        return events
    }

    func testRoundTripDownloadsVerifiesAndInstalls() async throws {
        let payload = Data("a real-enough gemma file".utf8)
        let cat = catalog(matching: payload)
        let provisioner = ModelProvisioner(
            catalog: cat, store: store,
            downloader: FakeModelDownloader(payload: payload))

        let events = try await collect(
            provisioner.provision(for: DeviceCapability(physicalMemory: 8 * gb)))

        XCTAssertEqual(events.first, .checkingDevice)
        XCTAssertTrue(events.contains(.verifying))
        XCTAssertTrue(events.contains { if case .downloading = $0 { return true }; return false })
        guard case .ready = events.last else {
            return XCTFail("should end ready, got \(String(describing: events.last))")
        }
        XCTAssertTrue(store.isInstalled(cat.primary))
        XCTAssertTrue(provisioner.isReady(for: DeviceCapability(physicalMemory: 8 * gb)))
    }

    func testUnsupportedDeviceStopsBeforeDownloading() async throws {
        let payload = Data("x".utf8)
        let provisioner = ModelProvisioner(
            catalog: catalog(matching: payload), store: store,
            downloader: FakeModelDownloader(payload: payload))

        let events = try await collect(
            provisioner.provision(for: DeviceCapability(physicalMemory: 1 * gb)))

        guard case .unsupportedDevice = events.last else {
            return XCTFail("low-RAM device should be unsupported")
        }
        XCTAssertFalse(events.contains { if case .downloading = $0 { return true }; return false })
    }

    func testAlreadyInstalledSkipsDownload() async throws {
        let payload = Data("cached".utf8)
        let cat = catalog(matching: payload)
        // Pre-install the file.
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try payload.write(to: temp)
        _ = try store.install(from: temp, as: cat.primary)

        let provisioner = ModelProvisioner(
            catalog: cat, store: store,
            downloader: FakeModelDownloader(payload: payload))
        let events = try await collect(
            provisioner.provision(for: DeviceCapability(physicalMemory: 8 * gb)))

        guard case .alreadyInstalled = events.last else {
            return XCTFail("present model should short-circuit")
        }
        XCTAssertFalse(events.contains { if case .downloading = $0 { return true }; return false })
    }

    func testCorruptDownloadFailsVerificationAndLeavesNothingInstalled() async throws {
        // Spec expects `good`, but the downloader delivers `bad` (wrong size+hash).
        let good = Data("the good bytes".utf8)
        let cat = catalog(matching: good)
        let provisioner = ModelProvisioner(
            catalog: cat, store: store,
            downloader: FakeModelDownloader(payload: Data("bad".utf8)))

        do {
            _ = try await collect(
                provisioner.provision(for: DeviceCapability(physicalMemory: 8 * gb)))
            XCTFail("verification should have thrown")
        } catch {
            XCTAssertTrue(error is ModelVerificationError)
        }
        XCTAssertFalse(store.isInstalled(cat.primary))
    }

    func testDownloadFailurePropagates() async throws {
        let payload = Data("y".utf8)
        let provisioner = ModelProvisioner(
            catalog: catalog(matching: payload), store: store,
            downloader: FakeModelDownloader(
                payload: payload, failure: LLMError.modelNotLoaded))

        do {
            _ = try await collect(
                provisioner.provision(for: DeviceCapability(physicalMemory: 8 * gb)))
            XCTFail("download error should propagate")
        } catch let error as LLMError {
            XCTAssertEqual(error, .modelNotLoaded)
        }
    }
}
