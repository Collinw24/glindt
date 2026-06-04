import Foundation

public struct SkillsScanner {
    public static func scan(context: ServerContext, transport: any ServerTransport) -> [HermesSkill] { [] }
}

public struct SkillBundlesScanner {
    public static func scan(context: ServerContext, transport: any ServerTransport) -> [HermesSkillBundle] { [] }
}

public struct CuratorService {
    public init(context: ServerContext) {}
    public func run() async throws {}
}

public struct ProjectDashboardService {
    public init(context: ServerContext) {}
    public func loadRegistry() -> ProjectRegistry { ProjectRegistry(projects: []) }
    public func saveRegistry(_ registry: ProjectRegistry) {}
    public func dashboardExists(for project: ProjectEntry) -> Bool { false }
    public func dashboardModificationDate(for project: ProjectEntry) -> Date? { nil }
    public func loadDashboard(for project: ProjectEntry) -> ProjectDashboard? { nil }
}

public struct SessionAttributionService {
    public init(context: ServerContext) {}
    public func projectPath(for sessionID: String) -> String? { nil }
    public func attribute(sessionID: String, toProjectPath: String) {}
    public func load() -> SessionProjectMap { SessionProjectMap() }
}

public struct LogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let level: String
    public let message: String
    public init(timestamp: Date, level: String, message: String) {
        self.timestamp = timestamp; self.level = level; self.message = message
    }
}

public struct HermesLogService {
    public init(context: ServerContext) {}
    public func fetchRecentEntries(limit: Int) async -> [LogEntry] { [] }
}

public struct GitBranchService {
    public init(context: ServerContext) {}
    public func branch(at path: String) async -> String? { nil }
}

public struct ProjectSlashCommandService {
    public init(context: ServerContext) {}
    public func loadCommands(at path: String) -> [ProjectSlashCommand] { [] }
    public func loadGlobalCommands() -> [ProjectSlashCommand] { [] }
    public func expand(_ command: ProjectSlashCommand, withArgument arg: String) -> String { "" }
    public static func parse(fileAt path: String, context: ServerContext) -> ProjectSlashCommand? { nil }
    public func save(_ command: ProjectSlashCommand, at projectPath: String) throws {}
    public func delete(named: String, at projectPath: String) throws {}
}

public struct SSHScriptRunner {
    public static func run(script: String, context: ServerContext, timeout: TimeInterval) async -> ProcessResult? { nil }
}

public struct ModelCatalogService {
    public init(context: ServerContext) {}
    public func build() async -> String? { nil }
}

public struct NousModelCatalogService {
    public init(apiToken: String) {}
}

public struct RemoteBackupService {
    public init(context: ServerContext) {}
}

public struct RemoteRestoreService {
    public init(context: ServerContext) {}
}

public struct HermesUpdaterCommandBuilder {
    public init() {}
    public static func updateArgv(capabilities: HermesCapabilities, unattended: Bool, checkOnly: Bool) -> [String] { ["update"] }
}
