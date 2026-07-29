import Darwin
import Foundation

@_silgen_name("flock")
private func processFlock(_ descriptor: Int32, _ operation: Int32) -> Int32

// The lock has a single lexical owner. Sendability allows acquisition off the
// cooperative executor while the descriptor remains locked across async work.
final class ProbeProcessLock: @unchecked Sendable {
    private var descriptor: Int32

    private init(descriptor: Int32) {
        self.descriptor = descriptor
    }

    static func acquire(
        filename: String,
        directoryURL: URL? = nil
    ) throws -> ProbeProcessLock {
        let directory = try directoryURL ?? ProbeSharedStores.directoryURL()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let url = directory.appending(path: filename)
        let descriptor = Darwin.open(url.path, O_CREAT | O_RDWR | O_CLOEXEC, mode_t(0o600))
        guard descriptor >= 0 else { throw currentPOSIXError() }
        guard processFlock(descriptor, LOCK_EX) == 0 else {
            let error = currentPOSIXError()
            Darwin.close(descriptor)
            throw error
        }
        return ProbeProcessLock(descriptor: descriptor)
    }

    func release() {
        guard descriptor >= 0 else { return }
        _ = processFlock(descriptor, LOCK_UN)
        Darwin.close(descriptor)
        descriptor = -1
    }

    deinit {
        release()
    }

    private static func currentPOSIXError() -> POSIXError {
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
}
