import Foundation

public protocol GlindtTransport: Sendable {
    func fetchSessions() async throws -> [HermesSession]
    func createSession() async throws -> HermesSession
    func fetchMessages(sessionId: String) async throws -> [HermesMessage]
    func deleteSession(sessionId: String) async throws
    func forkSession(sessionId: String) async throws -> HermesSession
    func fetchCapabilities() async throws -> HermesCapabilities
    func fetchSkills() async throws -> [HermesSkill]
    func healthCheck() async throws -> Bool
}

public actor GlindtHTTPTransport: GlindtTransport {
    private let client: HTTPClient

    public init(config: APIServerConfig) {
        self.client = HTTPClient(config: config)
    }

    public func fetchSessions() async throws -> [HermesSession] {
        try await client.fetchSessions()
    }

    public func createSession() async throws -> HermesSession {
        try await client.createSession()
    }

    public func fetchMessages(sessionId: String) async throws -> [HermesMessage] {
        try await client.fetchMessages(sessionId: sessionId)
    }

    public func deleteSession(sessionId: String) async throws {
        try await client.deleteSession(sessionId: sessionId)
    }

    public func forkSession(sessionId: String) async throws -> HermesSession {
        try await client.forkSession(sessionId: sessionId)
    }

    public func fetchCapabilities() async throws -> HermesCapabilities {
        try await client.fetchCapabilities()
    }

    public func fetchSkills() async throws -> [HermesSkill] {
        try await client.fetchSkills()
    }

    public func healthCheck() async throws -> Bool {
        try await client.healthCheck()
    }
}
