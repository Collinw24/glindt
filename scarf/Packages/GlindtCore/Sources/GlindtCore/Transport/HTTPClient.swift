import Foundation
#if canImport(os)
import os
#endif

public actor HTTPClient {
    private let config: APIServerConfig
    private let session: URLSession

    #if canImport(os)
    private let logger = Logger(subsystem: "com.glindt", category: "HTTPClient")
    #endif

    public init(config: APIServerConfig) {
        self.config = config
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: cfg)
    }

    private var authHeader: [String: String] {
        ["Authorization": "Bearer \(config.apiToken)", "Content-Type": "application/json"]
    }

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: URL(string: "\(config.baseURL)\(path)")!)
        req.httpMethod = method
        req.allHTTPHeaderFields = authHeader
        req.httpBody = body
        return req
    }

    private func getData(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPClientError.transport(NSError(domain: "HTTPClient", code: -1))
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw HTTPClientError.http(http.statusCode, body)
        }
        return data
    }

    private func getJSON(_ req: URLRequest) async throws -> Any {
        let data = try await getData(req)
        return try JSONSerialization.jsonObject(with: data)
    }

    public func healthCheck() async throws -> Bool {
        let req = makeRequest(path: "/health")
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    public func fetchSessions() async throws -> [HermesSession] {
        let json = try await getJSON(makeRequest(path: "/api/sessions"))
        guard let array = json as? [[String: Any]] else { return [] }
        return array.compactMap(HermesSession.from(dict:))
    }

    @discardableResult
    public func createSession() async throws -> HermesSession {
        let json = try await getJSON(makeRequest(path: "/api/sessions", method: "POST"))
        guard let dict = json as? [String: Any] else {
            throw HTTPClientError.decoding(NSError(domain: "HTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expected dict"]))
        }
        guard let session = HermesSession.from(dict: dict) else {
            throw HTTPClientError.decoding(NSError(domain: "HTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse session"]))
        }
        return session
    }

    public func fetchMessages(sessionId: String) async throws -> [HermesMessage] {
        let json = try await getJSON(makeRequest(path: "/api/sessions/\(sessionId)/messages"))
        guard let array = json as? [[String: Any]] else { return [] }
        return array.compactMap(HermesMessage.from(dict:))
    }

    public func deleteSession(sessionId: String) async throws {
        _ = try await getData(makeRequest(path: "/api/sessions/\(sessionId)", method: "DELETE"))
    }

    public func forkSession(sessionId: String) async throws -> HermesSession {
        let json = try await getJSON(makeRequest(path: "/api/sessions/\(sessionId)/fork", method: "POST"))
        guard let dict = json as? [String: Any],
              let session = HermesSession.from(dict: dict)
        else { throw HTTPClientError.decoding(NSError(domain: "HTTPClient", code: -1)) }
        return session
    }

    public func fetchCapabilities() async throws -> HermesCapabilities {
        let json = try await getJSON(makeRequest(path: "/v1/capabilities"))
        guard let dict = json as? [String: Any] else {
            return .empty
        }
        return HermesCapabilities.from(dict: dict) ?? .empty
    }

    public func fetchSkills() async throws -> [HermesSkill] {
        let json = try await getJSON(makeRequest(path: "/v1/skills"))
        guard let array = json as? [[String: Any]] else { return [] }
        return array.compactMap(HermesSkill.from(dict:))
    }
}

public enum HTTPClientError: Error, LocalizedError {
    case http(Int, String)
    case transport(Error)
    case decoding(Error)

    public var errorDescription: String? {
        switch self {
        case .http(let code, let body): return "HTTP \(code): \(body)"
        case .transport(let error): return error.localizedDescription
        case .decoding(let error): return "Decoding error: \(error.localizedDescription)"
        }
    }
}
