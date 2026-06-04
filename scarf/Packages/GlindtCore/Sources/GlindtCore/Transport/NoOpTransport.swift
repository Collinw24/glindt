import Foundation

public enum TransportError: Error, LocalizedError {
    case other(message: String)
    case commandFailed(exitCode: Int32, stderr: String)
    case timeout(seconds: TimeInterval)

    public var errorDescription: String? {
        switch self {
        case .other(let msg): return msg
        case .commandFailed(let code, let stderr): return "Command failed (exit \(code)): \(stderr)"
        case .timeout(let seconds): return "Command timed out after \(Int(seconds))s"
        }
    }

    public var diagnosticStderr: String {
        switch self {
        case .commandFailed(_, let stderr): return stderr
        case .other(let msg): return msg
        case .timeout: return "timeout"
        }
    }
}

struct NoOpTransport: ServerTransport {
    let contextID: ServerID
    let isRemote: Bool = false

    func readFile(_ path: String) throws -> Data {
        throw TransportError.other(message: "No transport available")
    }
    func writeFile(_ path: String, data: Data) throws {
        throw TransportError.other(message: "No transport available")
    }
    func fileExists(_ path: String) -> Bool { false }
    func stat(_ path: String) -> FileStat? { nil }
    func listDirectory(_ path: String) throws -> [String] {
        throw TransportError.other(message: "No transport available")
    }
    func createDirectory(_ path: String) throws {}
    func removeFile(_ path: String) throws {}
    func runProcess(executable: String, args: [String], stdin: Data?, timeout: TimeInterval?) throws -> ProcessResult {
        throw TransportError.other(message: "No transport available")
    }
    func streamLines(executable: String, args: [String]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish(throwing: TransportError.other(message: "No transport available")) }
    }
    func streamScript(_ script: String, timeout: TimeInterval) async throws -> ProcessResult {
        throw TransportError.other(message: "No transport available")
    }
    func watchPaths(_ paths: [String]) -> AsyncStream<WatchEvent> {
        AsyncStream { $0.finish() }
    }
#if !os(iOS)
    func makeProcess(executable: String, args: [String]) -> Process {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: executable)
        p.arguments = args
        return p
    }
#endif
}
