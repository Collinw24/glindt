#if canImport(Citadel)

import Foundation
import Citadel
import CryptoKit
import NIOCore
import GlindtCore

@available(iOS 18.0, macOS 15.0, *)
public actor SSHACPChannel: ACPChannel {
    private let client: SSHClient
    private var isClosed = false
    private let incomingContinuation: AsyncThrowingStream<String, Error>.Continuation
    private let stderrContinuation: AsyncThrowingStream<String, Error>.Continuation

    public nonisolated let incoming: AsyncThrowingStream<String, Error>
    public nonisolated let stderr: AsyncThrowingStream<String, Error>

    private var stdinWriter: TTYStdinWriter?
    private var exitCode: Int32?

    public init(client: SSHClient, command: String) async throws {
        self.client = client

        var (stream, cont) = AsyncThrowingStream.makeStream(of: String.self)
        self.incoming = stream
        self.incomingContinuation = cont

        var (estream, econt) = AsyncThrowingStream.makeStream(of: String.self)
        self.stderr = estream
        self.stderrContinuation = econt

        try await client.withExec(command, environment: []) { output, writer in
            self.stdinWriter = writer

            Task { [weak self] in
                var stdoutBuffer = ""
                do {
                    for try await chunk in output {
                        switch chunk {
                        case .stdout(let buffer):
                            let text = String(buffer: buffer)
                            stdoutBuffer.append(text)
                            while let newline = stdoutBuffer.firstIndex(of: "\n") {
                                let line = String(stdoutBuffer[..<newline])
                                stdoutBuffer.removeSubrange(...newline)
                                cont.yield(line)
                            }
                        case .stderr(let buffer):
                            let text = String(buffer: buffer)
                            if !text.isEmpty {
                                econt.yield(text)
                            }
                        @unknown default:
                            break
                        }
                    }
                    if !stdoutBuffer.isEmpty {
                        cont.yield(stdoutBuffer)
                    }
                    cont.finish()
                    econt.finish()
                } catch {
                    cont.finish(throwing: error)
                    econt.finish(throwing: error)
                }
            }
        }
    }

    public func send(_ line: String) async throws {
        guard !isClosed, let writer = stdinWriter else {
            throw ACPChannelError.writeEndClosed
        }
        let data = Data((line + "\n").utf8)
        var buffer = ByteBuffer(data: data)
        try await writer.write(buffer)
    }

    public func close() async {
        guard !isClosed else { return }
        isClosed = true
        incomingContinuation.finish()
        stderrContinuation.finish()
    }

    public var diagnosticID: String? {
        get async { nil }
    }

    public var lastExitCode: Int32? {
        get async { exitCode }
    }
}

#endif
