import Foundation

public struct APIServerConfig: Sendable, Hashable, Codable {
    public var serverURL: String
    public var apiToken: String
    public var displayName: String

    public init(
        serverURL: String,
        apiToken: String,
        displayName: String
    ) {
        self.serverURL = serverURL
        self.apiToken = apiToken
        self.displayName = displayName
    }

    var baseURL: String {
        var url = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !url.hasPrefix("http") {
            url = "https://" + url
        }
        return url
    }
}
