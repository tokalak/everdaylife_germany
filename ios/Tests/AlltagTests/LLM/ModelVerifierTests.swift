import XCTest
@testable import Alltag

/// A-22: verification accepts a good file and rejects truncation / tampering.
final class ModelVerifierTests: XCTestCase {
    private let verifier = ModelVerifier()
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func write(_ data: Data) throws -> URL {
        let url = directory.appendingPathComponent(UUID().uuidString)
        try data.write(to: url)
        return url
    }

    func testVerifiesMatchingSizeAndChecksum() throws {
        let payload = Data("gemma weights".utf8)
        let url = try write(payload)
        let spec = LLMTestFactory.spec(matching: payload)
        XCTAssertNoThrow(try verifier.verify(fileAt: url, against: spec))
    }

    func testRejectsSizeMismatch() throws {
        let payload = Data(repeating: 9, count: 100)
        let url = try write(payload)
        let spec = LLMModelSpec(
            id: "m", displayName: "M", runtime: .llamaCpp, quant: .q4_K_M,
            fileName: "m.gguf", sourceURL: URL(string: "https://x.test/m")!,
            expectedByteCount: 101, sha256: nil, contextWindowCap: 4096)
        XCTAssertThrowsError(try verifier.verify(fileAt: url, against: spec)) {
            guard case ModelVerificationError.sizeMismatch = $0 else {
                return XCTFail("expected sizeMismatch, got \($0)")
            }
        }
    }

    func testRejectsChecksumMismatchAtCorrectSize() throws {
        let payload = Data(repeating: 1, count: 64)
        let url = try write(payload)
        // Right size, wrong hash.
        let spec = LLMModelSpec(
            id: "m", displayName: "M", runtime: .llamaCpp, quant: .q4_K_M,
            fileName: "m.gguf", sourceURL: URL(string: "https://x.test/m")!,
            expectedByteCount: 64,
            sha256: String(repeating: "0", count: 64), contextWindowCap: 4096)
        XCTAssertThrowsError(try verifier.verify(fileAt: url, against: spec)) {
            guard case ModelVerificationError.checksumMismatch = $0 else {
                return XCTFail("expected checksumMismatch, got \($0)")
            }
        }
    }

    func testSkipsChecksumWhenSpecHasNone() throws {
        let payload = Data(repeating: 3, count: 32)
        let url = try write(payload)
        let spec = LLMModelSpec(
            id: "m", displayName: "M", runtime: .llamaCpp, quant: .q4_K_M,
            fileName: "m.gguf", sourceURL: URL(string: "https://x.test/m")!,
            expectedByteCount: 32, sha256: nil, contextWindowCap: 4096)
        XCTAssertNoThrow(try verifier.verify(fileAt: url, against: spec))
    }

    func testChecksumIsCaseInsensitive() throws {
        let payload = Data("abc".utf8)
        let url = try write(payload)
        let upper = LLMTestFactory.sha256Hex(payload).uppercased()
        let spec = LLMModelSpec(
            id: "m", displayName: "M", runtime: .llamaCpp, quant: .q4_K_M,
            fileName: "m.gguf", sourceURL: URL(string: "https://x.test/m")!,
            expectedByteCount: Int64(payload.count), sha256: upper,
            contextWindowCap: 4096)
        XCTAssertNoThrow(try verifier.verify(fileAt: url, against: spec))
    }
}
