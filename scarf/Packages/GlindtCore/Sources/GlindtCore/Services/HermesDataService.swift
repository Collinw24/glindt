import Foundation
#if canImport(os)
import os
#endif

public actor HermesDataService {
    #if canImport(os)
    private static let logger = Logger(subsystem: "com.glindt", category: "HermesDataService")
    #endif

    private let http: HTTPClient
    public let context: ServerContext
    public private(set) var lastOpenError: String?

    private var cachedSessions: [HermesSession]?
    private var cachedMessages: [String: [HermesMessage]] = [:]

    public init(context: ServerContext = .local) {
        self.context = context
        if case .api(let config) = context.kind {
            self.http = HTTPClient(config: config)
        } else {
            self.http = HTTPClient(config: APIServerConfig(serverURL: "", apiToken: "", displayName: ""))
        }
    }

    public init(config: APIServerConfig) {
        self.context = ServerContext(id: ServerID(), displayName: config.displayName, kind: .api(config))
        self.http = HTTPClient(config: config)
    }

    public func open() async -> Bool { true }
    @discardableResult public func refresh(forceFresh: Bool = false) async -> Bool { true }
    public func close() async {}

    public func fetchSessions(limit: Int? = nil) async -> [HermesSession] {
        if let cached = cachedSessions { return Array(cached.prefix(limit ?? cached.count)) }
        do {
            cachedSessions = try await http.fetchSessions()
            let sessions = cachedSessions ?? []
            return Array(sessions.prefix(limit ?? sessions.count))
        } catch {
            #if canImport(os)
            Self.logger.error("fetchSessions failed: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    public func fetchSession(id: String) async -> HermesSession? {
        let sessions = await fetchSessions()
        return sessions.first { $0.id == id }
    }

    public func fetchMessages(sessionId: String, limit: Int? = nil, before: Int? = nil) async -> [HermesMessage] {
        if let cached = cachedMessages[sessionId] {
            return Array(cached.prefix(limit ?? cached.count))
        }
        do {
            let messages = try await http.fetchMessages(sessionId: sessionId)
            cachedMessages[sessionId] = messages
            return Array(messages.prefix(limit ?? messages.count))
        } catch {
            #if canImport(os)
            Self.logger.error("fetchMessages failed: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    public func fetchSkeletonMessages(sessionId: String, limit: Int) async -> MessageFetchOutcome {
        do {
            let messages = try await http.fetchMessages(sessionId: sessionId)
            cachedMessages[sessionId] = messages
            return MessageFetchOutcome(messages: Array(messages.prefix(limit)), transportError: nil)
        } catch {
            #if canImport(os)
            Self.logger.error("fetchSkeletonMessages failed: \(error.localizedDescription)")
            #endif
            return MessageFetchOutcome(messages: [], transportError: error.localizedDescription)
        }
    }

    public func hydrateAssistantToolCalls(messageIds: [Int]) async -> [Int: [HermesToolCall]] { [:] }

    public func fetchToolResultsInRange(sessionId: String, minId: Int, maxId: Int) async -> [HermesMessage] { [] }

    public func fetchToolResult(callId: String) async -> String? { nil }

    public func fetchMessageFingerprint(sessionId: String) async -> MessageFingerprint? { nil }

    public func fetchMostRecentlyStartedSessionId(after: Date) async -> String? { nil }

    public func fetchMostRecentlyActiveSessionId() async -> String? { nil }

    public func fetchSessionPreviews(limit: Int) async -> [String: String] { [:] }

    public func fetchSessionsInPeriod(since: Date) async -> [HermesSession] { await fetchSessions() }

    public func fetchRecentToolCallSkeleton(limit: Int) async -> [HermesMessage] { [] }

    public func insightsSnapshot(since: Date) async -> [String: Any] { [:] }

    public struct SessionStats: Sendable {
        public let sessionCount: Int
        public let totalTokens: Int
        public let totalCost: Double
        public static let empty = SessionStats(sessionCount: 0, totalTokens: 0, totalCost: 0)
        public init(sessionCount: Int, totalTokens: Int, totalCost: Double) {
            self.sessionCount = sessionCount; self.totalTokens = totalTokens; self.totalCost = totalCost
        }
    }

    public func fetchStats() async -> SessionStats { .empty }
}

extension HermesDataService {
    public struct MessageFingerprint: Sendable, Equatable {
        public let count: Int
        public let latestId: Int
        public init(count: Int, latestId: Int) { self.count = count; self.latestId = latestId }
    }
}
