import Darwin
import Foundation

@_silgen_name("flock")
private func systemFlock(_ descriptor: Int32, _ operation: Int32) -> Int32

struct ProbeJSONLStore<Record: Codable & Sendable>: Sendable {
    let fileURL: URL

    func append(_ record: Record) throws {
        try ensureParentDirectory()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var data = try encoder.encode(record)
        data.append(0x0A)

        let descriptor = Darwin.open(fileURL.path, O_CREAT | O_RDWR, mode_t(0o600))
        guard descriptor >= 0 else { throw currentPOSIXError() }
        defer { Darwin.close(descriptor) }
        guard systemFlock(descriptor, LOCK_EX) == 0 else { throw currentPOSIXError() }
        defer { _ = systemFlock(descriptor, LOCK_UN) }

        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.synchronize()
        try compactIfNeeded(handle)
    }

    func read() throws -> [Record] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let descriptor = Darwin.open(fileURL.path, O_RDONLY)
        guard descriptor >= 0 else { throw currentPOSIXError() }
        defer { Darwin.close(descriptor) }
        guard systemFlock(descriptor, LOCK_SH) == 0 else { throw currentPOSIXError() }
        defer { _ = systemFlock(descriptor, LOCK_UN) }

        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        let data = try handle.readToEnd() ?? Data()
        return try decodeLines(data)
    }

    private func ensureParentDirectory() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func decodeLines(_ data: Data) throws -> [Record] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true)

        return try lines.enumerated().map { index, line in
            do {
                return try decoder.decode(Record.self, from: Data(line))
            } catch {
                throw ProbeStoreError.invalidJSONLine(index + 1)
            }
        }
    }

    private func compactIfNeeded(_ handle: FileHandle) throws {
        let size = try handle.seekToEnd()
        guard size > ProbeConstants.logRetentionBytes else { return }

        try handle.seek(toOffset: 0)
        let data = try handle.readToEnd() ?? Data()
        let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true)
        var compacted = Data()
        for line in lines.suffix(ProbeConstants.retainedLogLineCount) {
            compacted.append(contentsOf: line)
            compacted.append(0x0A)
        }

        try handle.truncate(atOffset: 0)
        try handle.seek(toOffset: 0)
        try handle.write(contentsOf: compacted)
        try handle.synchronize()
    }

    private func currentPOSIXError() -> POSIXError {
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
}

enum ProbeSharedStores {
    static func directoryURL(fileManager: FileManager = .default) throws -> URL {
        guard let url = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: ProbeConstants.appGroupIdentifier
        ) else {
            throw ProbeStoreError.missingAppGroup(ProbeConstants.appGroupIdentifier)
        }
        return url
    }

    static func logStore(directoryURL: URL? = nil) throws -> ProbeJSONLStore<ProbeLogEntry> {
        let directory = try directoryURL ?? self.directoryURL()
        return ProbeJSONLStore(fileURL: directory.appending(path: ProbeConstants.logFilename))
    }

    static func appendLog(
        source: String,
        level: ProbeLogLevel,
        message: String,
        directoryURL: URL? = nil
    ) throws {
        try logStore(directoryURL: directoryURL).append(
            ProbeLogEntry(source: source, level: level, message: message)
        )
    }
}
