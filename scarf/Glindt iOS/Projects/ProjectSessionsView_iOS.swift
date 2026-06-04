import SwiftUI
import GlindtCore

struct ProjectSessionsView_iOS: View {
    let project: ProjectEntry

    init(project: ProjectEntry) {
        self.project = project
    }

    var body: some View {
        Text("Project Sessions — coming soon").foregroundStyle(.secondary)
    }
}
