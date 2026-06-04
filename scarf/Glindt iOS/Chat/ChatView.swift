import SwiftUI
import GlindtCore
import GlindtIOS
import GlindtDesign
import os
#if canImport(PhotosUI)
import PhotosUI
#endif

#if canImport(SQLite3)

struct ChatView: View {
    let config: GlindtAppConfig

    @Environment(\.hermesCapabilities) private var capabilitiesStore
    @Environment(\.glindtAppConfig) private var appConfig
    @State private var controller: ChatController
    @State private var showSlashCommandsSheet = false
    @State private var showSlashMenu = false
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    @State private var isEncodingAttachment = false
    @State private var attachmentError: String?

    private static let maxAttachments = 5

    private var supportsImagePrompts: Bool {
        capabilitiesStore?.capabilities.hasACPImagePrompts ?? false
    }

    private var supportsActiveGoal: Bool {
        capabilitiesStore?.capabilities.hasGoals ?? false
    }

    private var supportsACPQueue: Bool {
        capabilitiesStore?.capabilities.hasACPQueue ?? false
    }

    private var filteredSlashCommands: [HermesSlashCommand] {
        let query = RichChatViewModel.slashMenuQuery(text: controller.draft)
        return RichChatViewModel.filterSlashCommands(
            controller.vm.availableCommands,
            query: query
        )
    }

    private var disabledSlashCommandNames: Set<String> {
        RichChatViewModel.disabledSlashCommandNames(
            isAgentWorking: controller.vm.isAgentWorking,
            hasActiveSession: controller.vm.sessionId != nil,
            capabilities: capabilitiesStore?.capabilities ?? .empty
        )
    }

    private var disabledSlashCommandReason: String? {
        RichChatViewModel.disabledSlashCommandReason(
            isAgentWorking: controller.vm.isAgentWorking,
            hasActiveSession: controller.vm.sessionId != nil,
            capabilities: capabilitiesStore?.capabilities ?? .empty
        )
    }
    @FocusState private var composerFocused: Bool

    init(config: GlindtAppConfig) {
        self.config = config
        let ctx = config.toAPIServerContext()
        _controller = State(initialValue: ChatController(config: config, context: ctx))
    }

    var body: some View {
        let _: Void = GlindtMon.event(.chatRender, "ios.ChatView.body")
        return VStack(spacing: 0) {
            connectionBanner
            errorBanner
            messageList
            Divider()
            if let hint = controller.vm.transientHint {
                steeringToast(hint)
            }
            composer
        }
        .background(GlindtColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    composerFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .accessibilityLabel("Hide keyboard")
                Spacer()
            }
        }
        .task(id: capabilitiesStore?.capabilities.versionLine ?? "") {
            controller.vm.publishCapabilities(capabilitiesStore?.capabilities ?? .empty)
        }
        .task { await controller.start() }
        .onChange(of: NetworkReachabilityService.shared.transitionTick) { _, _ in
            Task { await controller.handleReachabilityChange() }
        }
        .overlay {
            if case .failed(let msg) = controller.state {
                errorOverlay(msg)
            } else if controller.state == .connecting {
                connectingOverlay
            }
        }
        .sheet(item: Binding(
            get: { controller.vm.pendingPermission.map(PermissionWrapper.init) },
            set: { if $0 == nil { controller.vm.pendingPermission = nil } }
        )) { wrapper in
            PermissionSheet(permission: wrapper.value) { optionId in
                await controller.respondToPermission(
                    requestId: wrapper.value.requestId,
                    optionId: optionId
                )
            }
            .presentationDetents([.height(220), .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var messageList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if controller.vm.messages.isEmpty, controller.state == .ready {
                    if controller.vm.sessionId != nil {
                        resumedEmptyState
                    } else {
                        emptyState
                    }
                }
                if controller.vm.hasMoreHistory {
                    loadEarlierButton
                }
                ForEach(controller.vm.messages) { msg in
                    MessageBubble(
                        message: msg,
                        turnDuration: controller.vm.turnDuration(forMessageId: msg.id)
                    )
                    .equatable()
                    .id(msg.id)
                }
                if controller.vm.isGenerating {
                    HStack {
                        ProgressView()
                        Text("Agent is thinking...")
                            .font(.caption)
                            .foregroundStyle(GlindtColor.foregroundMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                } else if controller.vm.isPostProcessing {
                    HStack(spacing: 6) {
                        Image(systemName: "ellipsis")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("Finishing up...")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var loadEarlierButton: some View {
        Button {
            Task { await controller.vm.loadEarlier() }
        } label: {
            HStack(spacing: 6) {
                if controller.vm.isLoadingEarlier {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.up.circle")
                        .font(.caption)
                }
                Text(controller.vm.isLoadingEarlier ? "Loading earlier..." : "Load earlier messages")
                    .font(.caption)
            }
            .foregroundStyle(GlindtColor.foregroundMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(controller.vm.isLoadingEarlier)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Ask Hermes something")
                .font(.headline)
                .foregroundStyle(GlindtColor.foregroundMuted)
            Text("Connected to \(config.displayName)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var resumedEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Session resumed")
                .font(.headline)
                .foregroundStyle(GlindtColor.foregroundMuted)
            Text("Hermes has the context for this session, but the transcript isn't cached locally. Send a message to continue.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var connectionBanner: some View {
        switch controller.state {
        case .reconnecting(let attempt, let total):
            connectionBannerStrip(
                text: attempt == 0 ? "Resuming..." : "Reconnecting (\(attempt)/\(total))...",
                tint: GlindtColor.warning,
                showSpinner: true
            )
        case .offline(let reason):
            connectionBannerStrip(
                text: reason,
                tint: GlindtColor.danger,
                showSpinner: false
            )
        default:
            if controller.vm.isStreamingThoughtsOnly {
                connectionBannerStrip(
                    text: "Thinking...",
                    tint: GlindtColor.info,
                    showSpinner: true
                )
            } else {
                EmptyView()
            }
        }
    }

    private func connectionBannerStrip(
        text: String,
        tint: Color,
        showSpinner: Bool
    ) -> some View {
        HStack(spacing: 8) {
            if showSpinner {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(tint)
            } else {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(tint)
            }
            Text(text)
                .font(.caption)
                .foregroundStyle(tint)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.16))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private func steeringToast(_ hint: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrowshape.turn.up.right.fill")
                .foregroundStyle(.tint)
                .font(.caption)
            Text(hint)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.tint.opacity(0.12))
        .transition(.opacity)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: GlindtSpace.s2) {
            if showSlashMenu {
                IOSSlashCommandMenu(
                    commands: filteredSlashCommands,
                    agentHasCommands: !controller.vm.availableCommands.isEmpty,
                    disabledCommandNames: disabledSlashCommandNames,
                    disabledReason: disabledSlashCommandReason,
                    onSelect: { command in
                        controller.insertSlashCommand(command)
                        showSlashMenu = false
                        composerFocused = true
                    }
                )
                .background(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: GlindtRadius.lg)
                        .strokeBorder(GlindtColor.border, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: GlindtRadius.lg))
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 2)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if !controller.attachments.isEmpty || isEncodingAttachment || attachmentError != nil {
                attachmentStrip
            }
            composerRow
        }
        .padding(.horizontal, GlindtSpace.s3)
        .padding(.top, GlindtSpace.s2)
        .padding(.bottom, GlindtSpace.s2)
        .background(.regularMaterial)
        .onChange(of: controller.draft) { _, newValue in
            let next = RichChatViewModel.shouldShowSlashMenu(text: newValue)
            if next != showSlashMenu {
                showSlashMenu = next
            }
        }
        #if canImport(PhotosUI)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $pickerSelection,
            maxSelectionCount: max(0, Self.maxAttachments - controller.attachments.count),
            matching: .images
        )
        .onChange(of: pickerSelection) { _, items in
            ingestPickerItems(items)
        }
        #endif
    }

    @ViewBuilder
    private var attachmentStrip: some View {
        HStack(alignment: .center, spacing: 8) {
            if isEncodingAttachment {
                ProgressView().controlSize(.small)
                Text("Encoding...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(controller.attachments) { attachment in
                attachmentChip(attachment)
            }
            if let err = attachmentError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(GlindtColor.danger)
            }
            Spacer(minLength: 0)
            if !controller.attachments.isEmpty {
                Text("\(controller.attachments.count)/\(Self.maxAttachments)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func attachmentChip(_ attachment: ChatImageAttachment) -> some View {
        HStack(spacing: 4) {
            attachmentChipThumbnail(attachment)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Button {
                controller.attachments.removeAll { $0.id == attachment.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove attached image")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(GlindtColor.backgroundSecondary)
        )
    }

    @ViewBuilder
    private func attachmentChipThumbnail(_ attachment: ChatImageAttachment) -> some View {
        if let thumb = attachment.thumbnailBase64,
           let data = Data(base64Encoded: thumb),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(GlindtColor.backgroundSecondary)
        }
    }

    private var composerRow: some View {
        HStack(alignment: .bottom, spacing: GlindtSpace.s2) {
            if supportsImagePrompts {
                Button {
                    showPhotoPicker = true
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(
                            attachDisabled
                                ? GlindtColor.foregroundFaint
                                : GlindtColor.foregroundMuted
                        )
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(attachDisabled)
                .accessibilityLabel("Attach image")
            }
            TextField("Message...", text: $controller.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, GlindtSpace.s3)
                .padding(.vertical, GlindtSpace.s2)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: GlindtRadius.xl, style: .continuous)
                        .fill(GlindtColor.backgroundSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GlindtRadius.xl, style: .continuous)
                        .strokeBorder(GlindtColor.borderStrong, lineWidth: 1)
                )
                .disabled(controller.state != .ready)
                .submitLabel(.send)
                .focused($composerFocused)
                .onSubmit { Task { await controller.send() } }
                .onChange(of: controller.draft) { _, _ in
                    controller.scheduleDraftSave()
                }
            Button {
                Task { await controller.send() }
            } label: {
                ZStack {
                    Circle()
                        .fill(canSendComposer
                              ? GlindtColor.accent
                              : GlindtColor.backgroundTertiary)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(canSendComposer
                                         ? GlindtColor.onAccent
                                         : GlindtColor.foregroundFaint)
                }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .animation(GlindtAnimation.fast, value: canSendComposer)
            }
            .buttonStyle(.plain)
            .disabled(!canSendComposer)
            .accessibilityLabel("Send message")
        }
    }

    private var canSendComposer: Bool {
        guard controller.state == .ready else { return false }
        if !controller.attachments.isEmpty { return true }
        return !controller.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var attachDisabled: Bool {
        controller.state != .ready || controller.attachments.count >= Self.maxAttachments
    }

    #if canImport(PhotosUI)
    private func ingestPickerItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        let remainingSlots = Self.maxAttachments - controller.attachments.count
        let snapshot = Array(items.prefix(max(remainingSlots, 0)))
        pickerSelection = []
        guard !snapshot.isEmpty else { return }
        isEncodingAttachment = true
        Task { @MainActor in
            let outcomes = await withTaskGroup(
                of: (index: Int, attachment: ChatImageAttachment?, errorMessage: String?).self
            ) { group in
                for (index, item) in snapshot.enumerated() {
                    group.addTask {
                        do {
                            guard let data = try await item.loadTransferable(type: Data.self) else {
                                return (index, nil, nil)
                            }
                            let attachment = try await Task.detached(priority: .userInitiated) {
                                try ImageEncoder().encode(rawBytes: data, sourceFilename: nil)
                            }.value
                            return (index, attachment, nil)
                        } catch {
                            let message = (error as? LocalizedError)?.errorDescription ?? "Couldn't encode image"
                            return (index, nil, message)
                        }
                    }
                }
                var rows: [(index: Int, attachment: ChatImageAttachment?, errorMessage: String?)] = []
                for await row in group { rows.append(row) }
                return rows.sorted { $0.index < $1.index }
            }
            var firstError: String?
            for outcome in outcomes {
                if let attachment = outcome.attachment {
                    controller.attachments.append(attachment)
                } else if firstError == nil, let message = outcome.errorMessage {
                    firstError = message
                }
            }
            if let firstError {
                attachmentError = firstError
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    attachmentError = nil
                }
            }
            isEncodingAttachment = false
        }
    }
    #endif

    @State private var showErrorDetails: Bool = false

    @ViewBuilder
    private var errorBanner: some View {
        if let err = controller.vm.acpError {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        if let hint = controller.vm.acpErrorHint {
                            Text(hint)
                                .font(.callout)
                                .textSelection(.enabled)
                        }
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(GlindtColor.foregroundMuted)
                            .textSelection(.enabled)
                            .lineLimit(showErrorDetails ? nil : 2)
                    }
                    Spacer(minLength: 4)
                    if controller.vm.acpErrorDetails != nil {
                        Button(showErrorDetails ? "Hide" : "Details") {
                            showErrorDetails.toggle()
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                    Button {
                        let payload = [
                            controller.vm.acpErrorHint,
                            err,
                            controller.vm.acpErrorDetails
                        ]
                            .compactMap { $0 }
                            .joined(separator: "\n\n")
                        UIPasteboard.general.string = payload
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
                if showErrorDetails, let details = controller.vm.acpErrorDetails {
                    ScrollView(.vertical) {
                        Text(details)
                            .font(.caption2.monospaced())
                            .foregroundStyle(GlindtColor.foregroundMuted)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 140)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12))
        }
    }

    @ViewBuilder
    private var connectingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Connecting to \(config.displayName)...")
                .font(.callout)
                .foregroundStyle(GlindtColor.foregroundMuted)
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func errorOverlay(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            Text("Chat connection failed")
                .font(.headline)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(GlindtColor.foregroundMuted)
                .padding(.horizontal)
            Button("Retry") {
                Task { await controller.start() }
            }
            .buttonStyle(GlindtPrimaryButton())
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding()
    }
}

// MARK: - ChatController

@Observable
@MainActor
final class ChatController {
    enum State: Equatable {
        case idle
        case connecting
        case ready
        case reconnecting(attempt: Int, of: Int)
        case offline(reason: String)
        case failed(String)
    }

    private(set) var state: State = .idle
    var vm: RichChatViewModel
    var draft: String = ""
    var attachments: [ChatImageAttachment] = []

    let context: ServerContext
    private let apiConfig: APIServerConfig
    private var client: ACPClient?
    private var eventTask: Task<Void, Never>?
    private var healthMonitorTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var isHandlingDisconnect = false
    private var pendingDraftSave: Task<Void, Never>?
    private var lastActiveSessionID: String?

    private static let maxReconnectAttempts = 5
    private static let reconnectBaseDelay: UInt64 = 1_000_000_000
    private static let maxReconnectDelay: UInt64 = 16_000_000_000
    private static let stallDetectionSeconds: TimeInterval = 75

    private static let logger = Logger(
        subsystem: "com.glindt.ios",
        category: "ChatController"
    )

    private static let draftKeyPrefix = "glindt.chat.draft.v1"
    private static let draftMaxAge: TimeInterval = 7 * 24 * 60 * 60

    private static func draftKey(serverID: ServerID, sessionID: String?) -> String {
        "\(draftKeyPrefix).\(serverID.uuidString).\(sessionID ?? "_no_session")"
    }

    private static func draftTimestampKey(forKey key: String) -> String { key + ".ts" }

    private func saveDraft() {
        let key = Self.draftKey(serverID: context.id, sessionID: vm.sessionId)
        let tsKey = Self.draftTimestampKey(forKey: key)
        if draft.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: tsKey)
        } else {
            UserDefaults.standard.set(draft, forKey: key)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: tsKey)
        }
    }

    private func loadDraft() {
        let key = Self.draftKey(serverID: context.id, sessionID: vm.sessionId)
        if let saved = UserDefaults.standard.string(forKey: key), !saved.isEmpty {
            draft = saved
        }
    }

    private func clearStoredDraft() {
        let key = Self.draftKey(serverID: context.id, sessionID: vm.sessionId)
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: Self.draftTimestampKey(forKey: key))
    }

    func scheduleDraftSave() {
        pendingDraftSave?.cancel()
        pendingDraftSave = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.saveDraft()
        }
    }

    static func pruneStaleDrafts(now: Date = Date()) {
        let defaults = UserDefaults.standard
        let cutoff = now.timeIntervalSince1970 - draftMaxAge
        for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix(draftKeyPrefix) && key.hasSuffix(".ts")
        {
            guard let ts = defaults.object(forKey: key) as? TimeInterval, ts < cutoff else { continue }
            let baseKey = String(key.dropLast(3))
            defaults.removeObject(forKey: baseKey)
            defaults.removeObject(forKey: key)
        }
    }

    init(config: GlindtAppConfig, context: ServerContext) {
        self.apiConfig = config.apiConfig
        self.context = context
        self.vm = RichChatViewModel(context: context)
    }

    func insertSlashCommand(_ command: HermesSlashCommand) {
        if command.argumentHint != nil {
            draft = "/\(command.name) "
        } else {
            draft = "/\(command.name)"
        }
        scheduleDraftSave()
    }

    func start() async {
        if state == .connecting || state == .ready { return }
        state = .connecting
        vm.reset()

        let client: ACPClient
        if let sshConfig = config.sshConfig, let keyPEM = config.sshPrivateKeyPEM {
            let bundle = SSHKeyBundle(privateKeyPEM: keyPEM, publicKeySSHLine: "")
            let sshCtx = ServerContext(id: context.id, displayName: config.displayName, kind: .ssh(sshConfig))
            client = ACPClient.forGlindt(
                context: sshCtx,
                sshConfig: sshConfig,
                keyProvider: { bundle }
            )
        } else {
            client = ACPClient(context: context) { _ in
                throw ACPChannelError.launchFailed("No SSH config configured for ACP streaming. Please configure SSH credentials.")
            }
        }
        self.client = client

        vm.acpStderrProvider = { [weak client] in
            await client?.recentStderr ?? ""
        }

        do {
            try await client.start()
        } catch {
            state = .failed(error.localizedDescription)
            await vm.recordACPFailure(error, client: client)
            return
        }

        startACPEventLoop(client: client)
        startHealthMonitor(client: client)

        do {
            let home = config.serverURL
            let sessionId = try await client.newSession(cwd: home)
            vm.setSessionId(sessionId)
            loadDraft()
            state = .ready
            lastActiveSessionID = sessionId
        } catch {
            state = .failed(error.localizedDescription)
            await vm.recordACPFailure(error, client: client)
            await stop()
        }
    }

    func send() async {
        await GlindtMon.measureAsync(.chatStream, "ios.send") {
            await _sendImpl()
        }
    }

    private func _sendImpl() async {
        guard state == .ready, let client else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !attachments.isEmpty else { return }

        if !text.isEmpty,
           let intercept = RichChatViewModel.clientSideSlashCommand(for: text) {
            draft = ""
            clearStoredDraft()
            attachments = []
            switch intercept {
            case .newSession:
                await resetAndStartNewSession()
            }
            return
        }

        let sessionId = vm.sessionId ?? ""
        guard !sessionId.isEmpty else { return }
        let images = attachments
        attachments = []
        draft = ""
        clearStoredDraft()
        if !text.isEmpty {
            vm.addUserMessage(text: text)
        } else {
            vm.addUserMessage(text: "[image attached]")
        }

        let parsedSlash = RichChatViewModel.parseSlashName(text)
        switch parsedSlash.name {
        case "goal":
            let arg = RichChatViewModel.parseGoalArgument(parsedSlash.args)
            switch arg {
            case .set(let goalText):
                vm.recordActiveGoal(text: goalText)
                vm.transientHint = "Goal locked: \(RichChatViewModel.truncatedToastGoal(goalText))"
            case .clear:
                vm.recordActiveGoal(text: nil)
                vm.transientHint = "Goal cleared."
            case .empty:
                vm.transientHint = "Sent /goal — see the agent reply for current goal."
            }
            scheduleTransientHintClear(snapshot: vm.transientHint)
        case "subgoal":
            let arg = RichChatViewModel.parseSubgoalArgument(parsedSlash.args)
            switch arg {
            case .add(let subText):
                vm.recordSubgoalAdded(subText)
                vm.transientHint = "Subgoal added."
            case .remove(let idx):
                vm.recordSubgoalRemoved(idx)
                vm.transientHint = "Subgoal \(idx) removed."
            case .clear:
                vm.recordSubgoalsCleared()
                vm.transientHint = "Subgoals cleared."
            case .empty:
                vm.transientHint = "Sent /subgoal — see the agent reply for current subgoals."
            }
            scheduleTransientHintClear(snapshot: vm.transientHint)
        case "steer" where vm.isNonInterruptiveSlash(text):
            vm.transientHint = "Guidance queued — applies after the next tool call."
            scheduleTransientHintClear(snapshot: vm.transientHint)
        default:
            break
        }

        do {
            _ = try await client.sendPrompt(sessionId: sessionId, text: text, images: images)
        } catch {
            if case .reconnecting = state {
                if !text.isEmpty, draft.isEmpty {
                    draft = text
                    scheduleDraftSave()
                }
                vm.transientHint = "Message not sent — tap Send again after reconnecting."
                scheduleTransientHintClear(snapshot: vm.transientHint)
                return
            }
            await vm.recordACPFailure(error, client: client)
            if case .ready = state {
                state = .failed("Prompt failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func scheduleTransientHintClear(snapshot: String?) {
        Task { @MainActor [weak vm] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if vm?.transientHint == snapshot {
                vm?.transientHint = nil
            }
        }
    }

    func stop() async {
        eventTask?.cancel(); eventTask = nil
        healthMonitorTask?.cancel(); healthMonitorTask = nil
        reconnectTask?.cancel(); reconnectTask = nil
        if let client {
            await client.stop()
        }
        client = nil
        state = .idle
        lastActiveSessionID = nil
        isHandlingDisconnect = false
    }

    func resetAndStartNewSession() async {
        await stop()
        vm.reset()
        await start()
    }

    private func startACPEventLoop(client: ACPClient) {
        eventTask = Task { @MainActor [weak self] in
            let stream = await client.events
            for await event in stream {
                guard !Task.isCancelled else { break }
                GlindtMon.event(.chatStream, "ios.acpEvent", count: 1)
                GlindtMon.measure(.chatStream, "ios.handleACPEvent") {
                    self?.vm.handleACPEvent(event)
                }
            }
            if !Task.isCancelled {
                self?.handleConnectionDied()
            }
        }
    }

    private func startHealthMonitor(client: ACPClient) {
        healthMonitorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { break }
                let healthy = await client.isHealthy
                if !healthy {
                    self?.handleConnectionDied()
                    break
                }
                guard let self else { break }
                if self.vm.isAgentWorking {
                    let idle = await client.secondsSinceLastIncoming
                    if idle > Self.stallDetectionSeconds {
                        Self.logger.warning("ACP channel appears stalled — \(Int(idle))s since last byte")
                        self.handleConnectionDied()
                        break
                    }
                }
            }
        }
    }

    private func handleConnectionDied() {
        guard client != nil, !isHandlingDisconnect else { return }
        isHandlingDisconnect = true
        Self.logger.warning("ACP connection died")

        vm.finalizeOnDisconnect()

        let savedSessionId = vm.sessionId

        eventTask?.cancel(); eventTask = nil
        healthMonitorTask?.cancel(); healthMonitorTask = nil
        if let dead = client { Task { await dead.stop() } }
        client = nil

        guard let savedSessionId else {
            state = .failed("Connection lost")
            isHandlingDisconnect = false
            return
        }
        attemptReconnect(sessionId: savedSessionId)
    }

    func handleReachabilityChange() async {
        let satisfied = NetworkReachabilityService.shared.isSatisfied
        if !satisfied {
            reconnectTask?.cancel(); reconnectTask = nil
            if case .reconnecting = state {
                state = .offline(reason: "No network")
            }
            return
        }
        guard let id = lastActiveSessionID else { return }
        switch state {
        case .offline, .failed:
            attemptReconnect(sessionId: id)
        default:
            break
        }
    }

    private func attemptReconnect(sessionId: String) {
        reconnectTask?.cancel()
        reconnectTask = Task { @MainActor [weak self] in
            guard let self else { return }

            for attempt in 1...Self.maxReconnectAttempts {
                guard !Task.isCancelled else { return }
                state = .reconnecting(attempt: attempt, of: Self.maxReconnectAttempts)

                if attempt > 1 {
                    let delay = min(
                        Self.reconnectBaseDelay * UInt64(1 << (attempt - 1)),
                        Self.maxReconnectDelay
                    )
                    try? await Task.sleep(nanoseconds: delay)
                    guard !Task.isCancelled else { return }
                }

                let client: ACPClient
                if let sshConfig = config.sshConfig, let keyPEM = config.sshPrivateKeyPEM {
                    let bundle = SSHKeyBundle(privateKeyPEM: keyPEM, publicKeySSHLine: "")
                    let sshCtx = ServerContext(id: context.id, displayName: config.displayName, kind: .ssh(sshConfig))
                    client = ACPClient.forGlindt(context: sshCtx, sshConfig: sshConfig, keyProvider: { bundle })
                } else { continue }

                do {
                    try await client.start()
                    let cwd = config.serverURL
                    let resolvedSessionId: String
                    do {
                        resolvedSessionId = try await client.resumeSession(cwd: cwd, sessionId: sessionId)
                    } catch {
                        Self.logger.info("session/resume failed, trying session/load: \(error.localizedDescription)")
                        resolvedSessionId = try await client.loadSession(cwd: cwd, sessionId: sessionId)
                    }

                    self.client = client
                    vm.acpStderrProvider = { [weak client] in
                        await client?.recentStderr ?? ""
                    }
                    vm.setSessionId(resolvedSessionId)
                    vm.clearACPErrorState()

                    startACPEventLoop(client: client)
                    startHealthMonitor(client: client)
                    state = .ready
                    lastActiveSessionID = resolvedSessionId

                    isHandlingDisconnect = false
                    Self.logger.info("Reconnected on attempt \(attempt)")
                    return
                } catch {
                    Self.logger.warning("Reconnect attempt \(attempt) failed: \(error.localizedDescription)")
                    await client.stop()
                    continue
                }
            }

            guard !Task.isCancelled else { return }
            state = .failed("Connection lost")
            isHandlingDisconnect = false
        }
    }

    func respondToPermission(requestId: Int, optionId: String) async {
        guard let client else { return }
        await client.respondToPermission(requestId: requestId, optionId: optionId)
        vm.pendingPermission = nil
    }
}

private struct PermissionWrapper: Identifiable {
    let value: RichChatViewModel.PendingPermission
    var id: Int { value.requestId }
}

#endif // SQLite3
