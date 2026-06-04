import Foundation

/// Progress of an in-flight model download.
enum ModelDownloadEvent: Sendable, Equatable {
    /// Fractional progress in `0...1` (or `nil` fraction if the server didn't
    /// report a content length — show an indeterminate spinner then).
    case progress(Double?)
    /// Finished — the bytes are at this temporary URL, ready to verify + install.
    case completed(URL)
}

/// Fetches a model file to a temporary location, reporting progress (A-22).
///
/// A protocol so the orchestration (``ModelProvisioner``) is testable with a
/// fake that writes known bytes — the real network download can't run in CI.
/// The model is large (~3 GB), so implementations should stream to disk and
/// support cancellation (drop the stream → cancel).
protocol ModelDownloading: Sendable {
    func download(_ spec: LLMModelSpec) -> AsyncThrowingStream<ModelDownloadEvent, Error>
}

/// `URLSession`-backed downloader streaming to disk (A-22).
///
/// Uses `URLSession.bytes(for:)` and appends to a temp file in bounded blocks so
/// the ~3 GB payload never sits in memory, emitting throttled progress. Dropping
/// the stream cancels the in-flight request.
///
/// **Hardening follow-ups** (tracked under A-22, need the real endpoint to test):
/// HTTP-Range *resume* across launches and exponential-backoff retry. The
/// ``ModelDownloading`` seam means a more robust downloader can be swapped in
/// without touching ``ModelProvisioner``.
struct URLSessionModelDownloader: ModelDownloading {
    let session: URLSession
    /// Where partial downloads are staged before verify + install.
    let temporaryDirectory: URL
    /// Flush to disk + emit progress every N bytes (8 MB).
    private let flushInterval: Int64 = 8 * 1_024 * 1_024

    init(session: URLSession = .shared, temporaryDirectory: URL = FileManager.default.temporaryDirectory) {
        self.session = session
        self.temporaryDirectory = temporaryDirectory
    }

    func download(_ spec: LLMModelSpec) -> AsyncThrowingStream<ModelDownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await stream(spec, into: continuation)
                } catch is CancellationError {
                    continuation.finish(throwing: LLMError.cancelled)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func stream(
        _ spec: LLMModelSpec,
        into continuation: AsyncThrowingStream<ModelDownloadEvent, Error>.Continuation
    ) async throws {
        let destination = temporaryDirectory
            .appendingPathComponent("\(spec.id)-\(UUID().uuidString).part", isDirectory: false)

        let (bytes, response) = try await session.bytes(from: spec.sourceURL)
        let expected = response.expectedContentLength > 0
            ? response.expectedContentLength : spec.expectedByteCount

        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destination)
        defer { try? handle.close() }

        var buffer = Data()
        buffer.reserveCapacity(Int(flushInterval))
        var written: Int64 = 0

        for try await byte in bytes {
            try Task.checkCancellation()
            buffer.append(byte)
            if buffer.count >= flushInterval {
                try handle.write(contentsOf: buffer)
                written += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                continuation.yield(.progress(fraction(written, of: expected)))
            }
        }
        if !buffer.isEmpty {
            try handle.write(contentsOf: buffer)
            written += Int64(buffer.count)
        }
        continuation.yield(.progress(1.0))
        continuation.yield(.completed(destination))
        continuation.finish()
    }

    private func fraction(_ written: Int64, of total: Int64) -> Double? {
        guard total > 0 else { return nil }
        return min(1.0, Double(written) / Double(total))
    }
}
