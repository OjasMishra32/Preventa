import SwiftUI
import PhotosUI        // for image picker
import AVFoundation    // for tts + mic permission
import Vision          // for ocr
import UniformTypeIdentifiers
import UIKit

// ===== Helpers =====
extension View {
    /// Dismisses the keyboard (resigns first responder) from anywhere.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// NOTE: info.plist keys needed:
// - NSCameraUsageDescription           = "I use the camera so you can share photos for guidance."
// - NSPhotoLibraryAddUsageDescription  = "I save photos only if you choose."
// - NSPhotoLibraryUsageDescription     = "I need access to let you pick a photo."
// - NSSpeechRecognitionUsageDescription= "I convert your voice to text when you press and hold."
// - NSMicrophoneUsageDescription       = "I use the mic for voice notes."
// - OPENAI_API_KEY (String)            = "<your key>"

// MARK: - pulse chat view

struct PulseChatView: View {
    @StateObject private var vm = PulseChatVM()
    @GestureState private var dragOffsetX: CGFloat = 0
    @State private var showTimeline = false
    @State private var showBodyMap = false
    @AppStorage("ui.focus") private var focus = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        GeometryReader { geo in
            let drawerWidth = min(320, max(260, geo.size.width * 0.72))
            let columnWidth = min(720, geo.size.width) // Centered column on iPad, full width on iPhone

            ZStack(alignment: .leading) {
                PulseAnimatedBackground().ignoresSafeArea()
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })

                VStack(spacing: 0) {
                    // === Top Bar ===
                    TopBar(
                        title: vm.title,
                        medsDue: vm.today.medsDue,
                        checkinsDue: vm.today.checkinsDue,
                        streak: vm.today.streak,
                        onNew: { vm.historyOpen = false; vm.clearSession() },
                        onCloseDrawer: { withAnimation(.spring()) { vm.historyOpen.toggle() } },
                        onExport: vm.exportSession,
                        onDelete: vm.clearSession,
                        onOpenTimeline: { showTimeline = true },
                        onToggleFocus: { focus.toggle() },
                        focusEnabled: focus
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .frame(maxWidth: columnWidth)

                    // === Header Cluster (Today + Safety) ===
                    VStack(spacing: 10) {
                        TodayPulseCard(strip: vm.today)
                        SafetyBanner()
                    }
                    .padding(12)
                    .frame(maxWidth: columnWidth)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.14), lineWidth: 1))
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .opacity(focus ? 0 : 1)
                    .allowsHitTesting(!focus)

                    if let red = vm.redFlag {
                        RedFlagBanner(text: red, onResources: vm.openResources)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.horizontal, 14)
                            .padding(.top, 4)
                            .frame(maxWidth: columnWidth)
                            .opacity(focus ? 0 : 1)
                            .allowsHitTesting(!focus)
                    }

                    // === Messages ===
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(vm.messages) { msg in
                                    MessageRow(
                                        message: msg,
                                        onCopy: { vm.copyMessage(msg) },
                                        onEditResend: { vm.editAndResend(msg) },
                                        onBookmark: { vm.toggleBookmark(msg) },
                                        onAddPlan: { vm.handleInlineAction(.addPlan, source: msg) },
                                        onStartFollowup: { vm.handleInlineAction(.followup6h, source: msg) },
                                        onOpenLearn: { vm.handleInlineAction(.openLearn, source: msg) },
                                        onLogMed: { vm.handleInlineAction(.logMed, source: msg) },
                                        speak: { vm.speak(msg.text) }
                                    )
                                    .id(msg.id)
                                }
                                RecapPill { vm.requestRecap() }
                                    .padding(.top, 4)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: columnWidth, alignment: .center)
                            .frame(maxWidth: .infinity)
                        }
                        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
                        .onChange(of: vm.messages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(vm.messages.last?.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: vm.messages.last?.text ?? "") { _, _ in
                            // Also scroll when message text updates (for streaming)
                            if let lastId = vm.messages.last?.id {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isTextFieldFocused) { _, newValue in
                            // Scroll to bottom when keyboard appears to keep input visible
                            if newValue, let lastId = vm.messages.last?.id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        proxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }

                    // === Chips ===
                    ChipsStrip(
                        contextChips: vm.contextChips,
                        starterChips: vm.starterChips,
                        onTap: { vm.insertChipAndSend($0) },
                        onBodyMap: { showBodyMap = true }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
                    .frame(maxWidth: columnWidth)
                    .opacity(focus ? 0 : 1)
                    .allowsHitTesting(!focus)

                    // === Attachments ===
                    if !vm.attachments.isEmpty {
                        AttachmentPreviewRow(
                            items: vm.attachments,
                            onNote: vm.addNote(to:),
                            onMarkup: vm.markRegion(on:),
                            onRemove: vm.removeAttachment(_:)
                        )
                        .padding(.horizontal, 14)
                        .padding(.bottom, 4)
                        .transition(.opacity)
                        .frame(maxWidth: columnWidth)
                        .opacity(focus ? 0 : 1)
                        .allowsHitTesting(!focus)
                    }

                    if let pair = vm.comparePair {
                        BeforeAfterCompare(pair: pair)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                            .transition(.opacity)
                            .frame(maxWidth: columnWidth)
                            .opacity(focus ? 0 : 1)
                            .allowsHitTesting(!focus)
                    }

                    if let banner = vm.bannerText {
                        Banner(text: banner, isError: vm.bannerIsError)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                            .frame(maxWidth: columnWidth)
                            .opacity(focus ? 0 : 1)
                            .allowsHitTesting(!focus)
                    }

                    // spacer to allow scroll behind input bar
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dynamicTypeSize(.xSmall ... .accessibility5) // 👈 enables accessibility text scaling
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 12, coordinateSpace: .local)
                        .updating($dragOffsetX) { value, state, _ in
                            if value.translation.width > 18 && value.startLocation.x < 24 {
                                state = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 80 && value.startLocation.x < 24 {
                                withAnimation(.spring()) { vm.historyOpen = true }
                            } else if value.translation.width < -80 {
                                withAnimation(.spring()) { vm.historyOpen = false }
                            }
                        }
                )

                if vm.historyOpen {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) { vm.historyOpen = false }
                        }
                }

                HistoryDrawer(
                    sessions: vm.sessions,
                    currentId: vm.sessionId,
                    onSelect: { id in
                        vm.sessions[id] = "New Chat"
                        vm.loadSession(id)
                    },
                    onDelete: { vm.deleteSession($0) }
                )
                .frame(width: drawerWidth)
                .offset(x: vm.historyOpen ? 0 : -drawerWidth - 20)
                .transition(.move(edge: .leading))
                .accessibilityHidden(!vm.historyOpen)
                .shadow(radius: 12, y: 4)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                // Input Bar pinned to the safe area with proper padding
                InputBar(
                    text: $vm.currentInput,
                    hasAttachments: !vm.attachments.isEmpty,
                    sending: vm.sending,
                    isFocused: $isTextFieldFocused,
                    onSend: {
                        hideKeyboard()
                        isTextFieldFocused = false
                        vm.sendMessage()
                    },
                    onTray: {
                        hideKeyboard()
                        withAnimation(.spring()) { vm.showTray.toggle() }
                    },
                    onPhoto: { vm.pickFromLibrary = true },
                    onCamera: vm.openCamera,
                    onMicDown: vm.voiceDown,
                    onMicUp: vm.voiceUp
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12)))
                .overlay(Divider().background(.white.opacity(0.10)), alignment: .top)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)

                if vm.showTray {
                    AttachmentTray(
                        selection: $vm.photoItems,
                        onCamera: vm.openCamera,
                        onLibrary: { vm.pickFromLibrary = true },
                        onJournal: vm.openJournal,
                        onHydration: vm.quickHydration,
                        onVoiceDown: vm.voiceDown,
                        onVoiceUp: vm.voiceUp
                    )
                    .padding(.horizontal, 9)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .background(Color.black.opacity(0.6))
                    .overlay(Divider().background(.white.opacity(0.12)), alignment: .top)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 4) // avoids overlapping the home indicator
            .frame(maxWidth: 820)
        }
        .photosPicker(isPresented: $vm.pickFromLibrary, selection: $vm.photoItems, matching: .images)
        .onChange(of: vm.photoItems) { _, _ in vm.ingestPickedPhotos() }
        .onAppear { vm.bootstrap() }
        .navigationBarBackButtonHidden(false)
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $showBodyMap) {
            BodyMapView()
        }
        .sheet(isPresented: $showTimeline) {
            HealthTimelineView()
        }
    }
}

private struct SessionTabs: View {
    var sessions: [UUID: String]
    var currentId: UUID
    var onNew: () -> Void
    var onSelect: (UUID) -> Void
    var onRename: (UUID, String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: onNew) {
                    Label("New", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Brand.glow, in: Capsule())
                        .overlay(Capsule().stroke(Brand.chipStroke, lineWidth: 0.8))
                        .foregroundStyle(Brand.textPrimary)
                }
                ForEach(sessions.sorted(by: { $0.value < $1.value }), id: \.key) { id, title in
                    EditableTab(
                        title: title.isEmpty ? "Untitled" : title,
                        isActive: id == currentId,
                        onCommit: { onRename(id, $0) },
                        onTap: { onSelect(id) }
                    )
                }
            }
        }
    }
}

private struct EditableTab: View {
    @State private var editing = false
    @State private var draft = ""
    var title: String
    var isActive: Bool
    var onCommit: (String) -> Void
    var onTap: () -> Void

    var body: some View {
        Group {
            if editing {
                TextField("", text: $draft, onCommit: { editing = false; onCommit(draft) })
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Brand.surfaceA, in: Capsule())
                    .overlay(Capsule().stroke(Brand.chipStroke))
                    .foregroundStyle(Brand.textPrimary)
                    .frame(minWidth: 110)
            } else {
                Button {
                    Hx.tap()
                    onTap()
                } label: {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background((isActive ? AnyShapeStyle(Brand.glow) : AnyShapeStyle(Brand.surfaceA)), in: Capsule())
                        .overlay(Capsule().stroke(Brand.chipStroke))
                        .foregroundStyle(Brand.textPrimary)
                }
                .contextMenu {
                    Button("Rename") { draft = title; editing = true }
                }
            }
        }
    }
}


// MARK: - models

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var text: String
    var isUser: Bool
    var createdAt: Date
    var attachments: [Attachment] = []
    var actions: [InlineAction] = []
    var bookmarked: Bool = false
    var important: Bool = false
    var storeInJournal: Bool = true
    var confidenceNote: String? = nil

    init(id: UUID = UUID(),
         text: String,
         isUser: Bool,
         createdAt: Date = Date(),
         attachments: [Attachment] = [],
         actions: [InlineAction] = [],
         bookmarked: Bool = false,
         important: Bool = false,
         storeInJournal: Bool = true,
         confidenceNote: String? = nil) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.createdAt = createdAt
        self.attachments = attachments
        self.actions = actions
        self.bookmarked = bookmarked
        self.important = important
        self.storeInJournal = storeInJournal
        self.confidenceNote = confidenceNote
    }
}

struct Attachment: Identifiable, Equatable {
    enum Kind: String { case skin, eye, meal, label, unknown }
    let id = UUID()
    var image: UIImage
    var kind: Kind
    var note: String = ""
    var keptLocal: Bool = true
    var blurredFaces: Bool = false
}

struct TodayStrip {
    var medsDue: Int = 0
    var checkinsDue: Int = 0
    var streak: Int = 0
}

enum InlineAction: CaseIterable {
    case addPlan, followup6h, openLearn, logMed
    var title: String {
        switch self {
        case .addPlan: return "add to plan"
        case .followup6h: return "start 6h check-in"
        case .openLearn: return "open learn"
        case .logMed: return "log a med"
        }
    }
    var icon: String {
        switch self {
        case .addPlan: return "target"
        case .followup6h: return "clock"
        case .openLearn: return "book.closed"
        case .logMed: return "pills"
        }
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
    func downscaledIfNeeded(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0, size.width > 0, size.height > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        guard newSize.width > 0 && newSize.height > 0 else { return self }
        
        // Use autoreleasepool to ensure memory is released promptly
        return autoreleasepool {
            // Use scale of 0.0 for device scale to improve memory efficiency
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            defer { UIGraphicsEndImageContext() }
            draw(in: CGRect(origin: .zero, size: newSize))
            return UIGraphicsGetImageFromCurrentImageContext() ?? self
        }
    }
}

// MARK: - view model

@MainActor
final class PulseChatVM: ObservableObject {

    // state
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var sending: Bool = false
    
    // Track current send task to prevent concurrent requests
    private var currentSendTask: Task<Void, Never>?
    
    // Simple, reliable URLSession - create fresh for each request
    private func createGeminiSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }
    
    @Published var unlockedLevel: Int = UserDefaults.standard.integer(forKey: "unlockedLevel") == 0 ? 1 : UserDefaults.standard.integer(forKey: "unlockedLevel")
    // attachments / tray
    @Published var showTray: Bool = false
    @Published var pickFromLibrary: Bool = false
    @Published var photoItems: [PhotosPickerItem] = []
    @Published var attachments: [Attachment] = []
    @Published var keepLocalOnly: Bool = true
    @Published var blurFaces: Bool = false
    @Published var comparePair: (UIImage, UIImage)? = nil

    // speech + tts
    private let speaker = AVSpeechSynthesizer()
    @Published var isRecordingVoice: Bool = false

    // ui chrome
    @Published var bannerText: String? = nil
    @Published var bannerIsError: Bool = false
    @Published var redFlag: String? = nil
    @Published var historyOpen: Bool = false

    // sessions / titles
    @Published var title: String = "Preventa Pulse"
    let sessionId: UUID = UUID()
    @Published var sessions: [UUID: String] = [:]
    var today = TodayStrip(medsDue: 1, checkinsDue: 1, streak: 4)

    // helpers
    private let historyLimit = 10
    private let tokenDebug: Bool = true

    // chips
    let contextChips = ["sleep", "stress", "hydration", "pain 0–10", "duration", "triggers"]
    let starterChips = ["i have a headache", "can’t sleep", "what should i track today?"]

    // MARK: boot

    func bootstrap() {
        if messages.isEmpty {
            messages.append(ChatMessage(text: "Hi, I'm Preventa Pulse. Tell me what's going on — or tap the tray to share a photo. I'll ask quick follow-ups and suggest safe next steps.", isUser: false))
        }
        sessions[sessionId] = "New Session"
        
        // Check for body map context and auto-send it
        checkAndSendBodyMapContext()
    }
    
    // MARK: Body Map Auto-Send
    
    private func checkAndSendBodyMapContext() {
        // Check for body map context from UserDefaults
        guard let bodyMapContext = UserDefaults.standard.string(forKey: "bodyMap.context"),
              !bodyMapContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Clear the UserDefaults immediately to prevent re-sending
        UserDefaults.standard.removeObject(forKey: "bodyMap.context")
        
        // Format the body map data as a user message
        let bodyMapMessage = """
        I'm experiencing pain or discomfort:
        \(bodyMapContext)
        
        Can you help me understand what might be causing this and what I should do?
        """
        
        // Set currentInput with body map data so sendMessage() will send it
        currentInput = bodyMapMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Automatically send the message to get AI response
        // Small delay to ensure UI is ready and bootstrap() completes
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay to ensure UI is ready
            sendMessage()
        }
    }

    // MARK: input

    func insertChipAndSend(_ chip: String) {
        currentInput = chip
        sendMessage()
    }

    func startFromBodyMap() {
        messages.append(ChatMessage(text: "body map → which area is bothering you? try: head, eyes, throat, chest, stomach, back, skin, joints.", isUser: false))
    }

    // MARK: attachments flow
    // Uses Data/URL (UIImage is not Transferable). Works across iOS 17/18+ incl. HEIC/HEIF.
    func ingestPickedPhotos() {
        let items = photoItems
        let localOnly = keepLocalOnly
        let blur = blurFaces
        
        Task.detached(priority: .userInitiated) {
            var fresh: [Attachment] = []

            // Process images sequentially to prevent memory spikes (was parallel)
            for item in items {
                let attachment: Attachment? = await Task {
                        var ui: UIImage?

                        // 1) Try raw Data first
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            ui = UIImage(data: data)
                        }

                        // 2) Fallback to URL
                        if ui == nil, let url = try? await item.loadTransferable(type: URL.self) {
                            let _ = url.startAccessingSecurityScopedResource()
                            defer { url.stopAccessingSecurityScopedResource() }
                            if let data = try? Data(contentsOf: url) {
                                ui = UIImage(data: data)
                            }
                        }

                        guard let base = ui else { return nil }

                        // Normalize + downscale on background thread
                        // Reduced from 2000 to 1200 to prevent memory issues
                        let image = base.fixedOrientation().downscaledIfNeeded(maxDimension: 1200)
                        let clean = localOnly ? image : PulseChatVM.stripEXIF(image)
                        let kind = PulseChatVM.autoCategorize(image: clean)

                        return Attachment(image: clean, kind: kind, keptLocal: localOnly, blurredFaces: blur)
                }.value
                
                if let attachment = attachment {
                    fresh.append(attachment)
                }
            }

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if !fresh.isEmpty {
                    self.attachments.append(contentsOf: fresh)
                    self.autoCompareCandidate()
                    self.autoSuggestFromAttachments(fresh)
                }
                self.photoItems.removeAll()
            }
            
            if fresh.isEmpty && !items.isEmpty {
                await MainActor.run { [weak self] in
                    self?.banner("couldn't read that photo (format/permissions). try another or re-grant Photos access in Settings.", error: true)
                }
            }
        }
    }

    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            banner("Camera not available on this device", error: true)
            return
        }
        // You will need a UIViewControllerRepresentable to wrap UIImagePickerController
        banner("Camera picker not yet implemented (stub).")
    }

    func addNote(to id: UUID) {
        if let idx = attachments.firstIndex(where: { $0.id == id }) {
            let base = attachments[idx].note
            let new = (base.isEmpty ? "note" : base) + " "
            attachments[idx].note = new
        }
    }

    func markRegion(on id: UUID) {
        if let idx = attachments.firstIndex(where: { $0.id == id }) {
            attachments[idx].note += (attachments[idx].note.isEmpty ? "" : " ") + "[marked region]"
        }
    }

    func removeAttachment(_ id: UUID) {
        attachments.removeAll { $0.id == id }
        autoCompareCandidate()
    }

    nonisolated private static func stripEXIF(_ image: UIImage) -> UIImage {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return image }
        return UIImage(data: data) ?? image
    }

    nonisolated private static func autoCategorize(image: UIImage) -> Attachment.Kind {
        guard let cg = image.cgImage else { return .unknown }
        let width = cg.width, height = cg.height
        guard let data = cg.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return .unknown }
        var r=0, g=0, b=0, count=0
        for y in stride(from: 0, to: height, by: max(1, height/20)) {
            for x in stride(from: 0, to: width, by: max(1, width/20)) {
                let bytesPerPixel = cg.bitsPerPixel / 8
                guard bytesPerPixel >= 3 else { continue }
                let idx = (y * cg.bytesPerRow) + (x * bytesPerPixel)
                b += Int(ptr[idx])
                g += Int(ptr[idx+1])
                r += Int(ptr[idx+2])
                count += 1
            }
        }
        if count == 0 { return .unknown }
        let avgR = r/count, avgG = g/count, avgB = b/count
        if avgR > 140 && avgG > 120 && avgB > 110 { return .skin }
        if avgB > avgR + 30 { return .eye }
        return .unknown
    }

    private func autoCompareCandidate() {
        let kinds = Dictionary(grouping: attachments, by: { $0.kind })
        if let group = kinds.values.first(where: { $0.count >= 2 }) {
            let pair = Array(group.prefix(2))
            comparePair = (pair[0].image, pair[1].image)
        } else {
            comparePair = nil
        }
    }

    private func autoSuggestFromAttachments(_ items: [Attachment]) {
        if items.contains(where: { $0.kind == .label }) {
            messages.append(ChatMessage(text: "i can try to read that med label — want me to extract the name/dose?", isUser: false, actions: [.logMed]))
            if let first = items.first(where: { $0.kind == .label }) {
                Task { await runOCR(on: first.image) }
            }
        } else if items.contains(where: { $0.kind == .skin }) {
            messages.append(ChatMessage(text: "i see a skin photo — do you want a follow-up check-in tomorrow to track changes?", isUser: false, actions: [.followup6h]))
        } else if items.contains(where: { $0.kind == .meal }) {
            messages.append(ChatMessage(text: "nice meal snapshot — want quick tips from learn on balanced plates?", isUser: false, actions: [.openLearn]))
        }
    }

    // MARK: voice + tts

    func voiceDown() {
        isRecordingVoice = true
        banner("listening… (hold, then release to send)")
    }

    func voiceUp() {
        guard isRecordingVoice else { return }
        isRecordingVoice = false
        currentInput = currentInput.isEmpty ? "here’s what i said out loud…" : currentInput
        sendMessage()
        banner(nil)
    }

    func speak(_ text: String) {
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        utt.rate = 0.48
        speaker.speak(utt)
    }

    // MARK: send / api

    func sendMessage() {
        let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !attachments.isEmpty else { return }
        
        // CRITICAL FIX: Prevent concurrent sends
        guard !sending else {
            print("⚠️ PulseChatVM: Already sending, ignoring duplicate request")
            return
        }
        
        // CRITICAL FIX: Cancel any existing task
        currentSendTask?.cancel()
        currentSendTask = nil
        
        let userMsg = ChatMessage(text: trimmed.isEmpty ? "[shared photo]" : trimmed, isUser: true, attachments: attachments)
        messages.append(userMsg)
        currentInput = ""
        attachments.removeAll()
        comparePair = nil

        let typingId = UUID()
        messages.append(ChatMessage(id: typingId, text: "…", isUser: false))

        banner(nil)

        // CRITICAL FIX: Set sending and create task atomically to prevent race conditions
        sending = true
        
        // CRITICAL FIX: Store task reference and check cancellation
        currentSendTask = Task { @MainActor [weak self] in
            // CRITICAL FIX: Capture sending flag reset early to handle nil self case
            guard let self = self else {
                // If self is nil, we can't access sending directly
                // But the Task was created, so we handle this in the outer scope
                print("⚠️ PulseChatVM: Self is nil in Task")
                return
            }
            
            // CRITICAL FIX: Ensure sending is ALWAYS reset even on cancellation or errors
            defer {
                self.sending = false
                self.currentSendTask = nil
                print("📥 PulseChatVM: Setting sending = false (defer)")
            }
            
            // CRITICAL FIX: Check cancellation immediately
            guard !Task.isCancelled else {
                print("⚠️ PulseChatVM: Task cancelled before API call")
                if let idx = self.messages.firstIndex(where: { $0.id == typingId }) {
                    self.messages.remove(at: idx)
                }
                return
            }
            
            print("📤 PulseChatVM: Starting API call...")
            print("📤 PulseChatVM: User input: \(userMsg.text.prefix(50))...")
            print("📤 PulseChatVM: History count: \(self.recentHistory().count)")
            
            // Pass attachments to fetchAIReply for image support
            // Note: fetchAIReply returns error messages as strings, doesn't throw
            let reply = await self.fetchAIReply(history: self.recentHistory(), userInput: userMsg.text, attachments: userMsg.attachments)
            
            // CRITICAL FIX: Check cancellation after API call
            guard !Task.isCancelled else {
                print("⚠️ PulseChatVM: Task cancelled after API call")
                if let idx = self.messages.firstIndex(where: { $0.id == typingId }) {
                    self.messages.remove(at: idx)
                }
                return
            }
            
            print("📥 PulseChatVM: Received reply length: \(reply.count)")
            print("📥 PulseChatVM: Reply preview: \(reply.prefix(100))...")
            
            // Remove typing indicator first
            if let idx = self.messages.firstIndex(where: { $0.id == typingId }) {
                self.messages.remove(at: idx)
            }
            
            // Always show the reply, even if it's an error message
            let trimmedReply = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedReply.isEmpty else {
                print("⚠️ PulseChatVM: Reply is empty after trimming")
                self.messages.append(ChatMessage(text: "I'm having trouble responding right now. Please check the console logs for details.", isUser: false))
                return
            }
            
            print("✅ PulseChatVM: Reply received (\(trimmedReply.count) chars), will stream/show it")
            
            // CRITICAL FIX: Check cancellation before streaming
            guard !Task.isCancelled else {
                print("⚠️ PulseChatVM: Task cancelled before streaming")
                return
            }
            
            // Stream the reply
            await self.streamReply(reply)
            
            // CRITICAL FIX: Final cancellation check
            guard !Task.isCancelled else {
                print("⚠️ PulseChatVM: Task cancelled after streaming")
                return
            }

            if self.title.lowercased() == "new session" || self.title.lowercased() == "preventa pulse",
               let first = self.messages.first(where: { $0.isUser })?.text {
                let compact = first.lowercased().prefix(30)
                self.title = String(compact)
                self.sessions[self.sessionId] = self.title
            }
        }
        
        // CRITICAL FIX: Add a timeout safety mechanism to reset sending if it gets stuck
        // This handles edge cases where the task might complete but not reset sending
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000_000) // 3 minutes max
            if self.sending && self.currentSendTask?.isCancelled != true {
                print("⚠️ PulseChatVM: Timeout safety - resetting stuck sending flag")
                self.sending = false
                self.currentSendTask = nil
            }
        }
    }

    private func recentHistory() -> [(role: String, content: String)] {
        // Filter out typing indicators and empty messages
        let validMessages = messages.filter { msg in
            !(msg.text == "…" || msg.text.isEmpty)
        }
        // CRITICAL FIX: Limit history to 6 messages to prevent issues
        let last = Array(validMessages.suffix(6))
        return last.map { (role: $0.isUser ? "user" : "assistant", content: $0.text) }
    }

    private func streamReply(_ text: String) async {
        guard !text.isEmpty else {
            await MainActor.run {
                messages.append(ChatMessage(text: "I received an empty response. Please try again.", isUser: false))
            }
            return
        }
        
        // CRITICAL FIX: Check for cancellation
        guard !Task.isCancelled else {
            print("⚠️ PulseChatVM: Stream cancelled")
            return
        }
        
        var buffer = ""
        let chars = Array(text)
        let batchSize = max(3, min(text.count / 20, 10))
        
        await MainActor.run {
            messages.removeAll { $0.text == "…" && !$0.isUser }
        }
        
        for i in stride(from: 0, to: chars.count, by: batchSize) {
            // CRITICAL FIX: Check cancellation during streaming
            guard !Task.isCancelled else {
                print("⚠️ PulseChatVM: Streaming cancelled mid-stream")
                return
            }
            
            let endIdx = min(i + batchSize, chars.count)
            let chunk = chars[i..<endIdx]
            buffer.append(contentsOf: chunk)
            
            await MainActor.run {
                if let lastIdx = messages.indices.last,
                   !messages[lastIdx].isUser {
                    let oldMsg = messages[lastIdx]
                    messages[lastIdx] = ChatMessage(
                        id: oldMsg.id,
                        text: buffer,
                        isUser: oldMsg.isUser,
                        createdAt: oldMsg.createdAt,
                        attachments: oldMsg.attachments,
                        actions: oldMsg.actions,
                        bookmarked: oldMsg.bookmarked,
                        important: oldMsg.important,
                        storeInJournal: oldMsg.storeInJournal,
                        confidenceNote: oldMsg.confidenceNote
                    )
                } else {
                    messages.append(ChatMessage(text: buffer, isUser: false))
                }
            }
            
            // CRITICAL FIX: Check cancellation before sleep
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: 8_000_000)
        }
        
        await MainActor.run {
            // Message already finalized during streaming
            if !messages.isEmpty, let lastIdx = messages.indices.last, !messages[lastIdx].isUser {
                let oldMsg = messages[lastIdx]
                // Replace entire message to trigger SwiftUI update
                messages[lastIdx] = ChatMessage(
                    id: oldMsg.id,
                    text: buffer, // Ensure final text is set
                    isUser: oldMsg.isUser,
                    createdAt: oldMsg.createdAt,
                    attachments: oldMsg.attachments,
                    actions: suggestedActions(for: text),
                    bookmarked: oldMsg.bookmarked,
                    important: oldMsg.important,
                    storeInJournal: oldMsg.storeInJournal,
                    confidenceNote: confidenceSuffix(for: text)
                )
            }
        }

        await MainActor.run {
            // 🔴 Red-flag detection + mood update
            redFlag = detectRedFlags(text)
            if redFlag != nil {
                UserDefaults.standard.setValue("urgent", forKey: "ui.mood")
            } else {
                UserDefaults.standard.setValue("neutral", forKey: "ui.mood")
            }
        }

        await MainActor.run {
            if tokenDebug {
                banner("chars ~\(text.count)  •  context msgs \(min(messages.count, historyLimit))", error: false)
            }
        }
    }

    private func suggestedActions(for text: String) -> [InlineAction] {
        var out: [InlineAction] = []
        let lower = text.lowercased()
        if lower.contains("habit") || lower.contains("plan") { out.append(.addPlan) }
        if lower.contains("check") || lower.contains("follow") { out.append(.followup6h) }
        if lower.contains("learn") || lower.contains("read") { out.append(.openLearn) }
        if lower.contains("med") || lower.contains("dose") { out.append(.logMed) }

        // 🟢 Calm mood keywords
        if lower.contains("relax") || lower.contains("breath") || lower.contains("sleep") {
            UserDefaults.standard.setValue("calm", forKey: "ui.mood")
        }

        return Array(Set(out))
    }

    private func confidenceSuffix(for text: String) -> String? {
        let words = ["might", "could", "maybe", "if", "consider"]
        return words.contains(where: { text.lowercased().contains($0) }) ? "i’m not diagnosing — here are cautious next steps." : nil
    }

    private func detectRedFlags(_ text: String) -> String? {
        let flags = ["severe chest pain", "trouble breathing", "one-sided weakness", "suicidal"]
        for f in flags where text.lowercased().contains(f) {
            return "this could be urgent — consider emergency care now."
        }
        return nil
    }

    // Normalize AI text into clean, professional, chat-friendly paragraphs
    private func formatAIResponse(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Replace em/en dashes with simple hyphen
        text = text.replacingOccurrences(of: "\u{2014}", with: "-")
                   .replacingOccurrences(of: "\u{2013}", with: "-")

        // Remove any leftover section labels the model might emit
        let labels = ["Title:", "Symptoms/Context:", "Likely Contributors:", "What To Do Now:", "Watch-outs:", "Follow-up:"]
        for l in labels { text = text.replacingOccurrences(of: l, with: "") }

        // Normalize spacing around punctuation
        text = text.replacingOccurrences(of: "  ", with: " ")
        text = text.replacingOccurrences(of: "; ", with: ". ")

        // Split into sentences and regroup into 1–3 short paragraphs
        let sentences = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var chunks: [String] = []
        var current = ""
        for s in sentences {
            let candidate = current.isEmpty ? s + "." : current + " " + s + "."
            if candidate.count > 160 { // keep paragraphs readable
                if !current.isEmpty { chunks.append(current) }
                current = s + "."
            } else {
                current = candidate
            }
        }
        if !current.isEmpty { chunks.append(current) }

        // Re-join with blank lines between short paragraphs
        text = chunks.joined(separator: "\n\n")

        // Collapse excessive blank lines to at most two
        while text.contains("\n\n\n") { text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n") }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: ai call — Google Gemini API with image support
    private func fetchAIReply(history: [(role: String, content: String)], userInput: String, attachments: [Attachment] = []) async -> String {
        struct HTTPError: Error { let status: Int; let body: String }
        func fail(_ msg: String) async -> String {
            await MainActor.run {
                banner(msg, error: true)
            }
            return "I'm having trouble connecting right now. Please check your internet connection and try again."
        }

        // 0) API key - Gemini only (no fallback)
        guard let geminiRaw = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !geminiRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              geminiRaw.trimmingCharacters(in: .whitespacesAndNewlines) != "YOUR_GEMINI_API_KEY_HERE" else {
            print("❌ PulseChat: Gemini API key not found")
            return await fail("gemini api key not found. get a free key from ai.google.dev and add GEMINI_API_KEY to Info.plist")
        }
        
        let geminiKey = geminiRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        print("✅ PulseChat: Gemini API key found: \(geminiKey.prefix(10))...")

        // 1) Messages with comprehensive HealthKit context
        var contextNotes = ""
        
        // HealthKit data
        if HealthKitManager.shared.isAuthorized {
            let healthData = HealthKitManager.shared.healthData
            var healthSummary: [String] = []
            
            if healthData.steps > 0 {
                healthSummary.append("Steps: \(healthData.steps) (goal: \(healthData.stepsGoal))")
            }
            if healthData.heartRate > 0 {
                healthSummary.append("Heart rate: \(healthData.heartRate) bpm")
            }
            if healthData.sleepHours > 0 {
                healthSummary.append("Sleep: \(String(format: "%.1f", healthData.sleepHours)) hours")
            }
            if healthData.activeCalories > 0 {
                healthSummary.append("Active calories: \(healthData.activeCalories) kcal")
            }
            if healthData.dietaryCalories > 0 {
                healthSummary.append("Food calories: \(healthData.dietaryCalories) kcal")
            }
            if healthData.waterIntakeOz > 0 {
                healthSummary.append("Water: \(String(format: "%.1f", healthData.waterIntakeOz)) oz")
            }
            if let bmi = healthData.bmi {
                healthSummary.append("BMI: \(String(format: "%.1f", bmi))")
            }
            if healthData.weight > 0 {
                healthSummary.append("Weight: \(String(format: "%.1f", healthData.weight)) lbs")
            }
            
            if !healthSummary.isEmpty {
                contextNotes += "\n\nHealth data from Apple Health:\n" + healthSummary.joined(separator: "\n")
            }
        }
        
        // Note: Body map context is handled in bootstrap() - it's automatically sent as a user message
        // No need to add it to context notes here since it's already part of the conversation
        
        // Recent meals context
        let recentMeals = FoodTrackerManager.shared.meals.prefix(3)
        if !recentMeals.isEmpty {
            let mealsSummary = recentMeals.map { "\($0.name): \($0.calories) kcal" }.joined(separator: ", ")
            contextNotes += "\n\nRecent meals: \(mealsSummary)"
        }
        
        // Note: Body map context is handled in bootstrap() - it's automatically sent as a user message
        // No need to add it to context notes here since it's already part of the conversation
        
        let system =
        """
        You are Preventa Pulse — a warm, intelligent preventive health companion. You help users understand patterns,
        reduce risk, and build sustainable micro-habits. You reason medically and preventively, but you do not diagnose.
        Tone: calm, human, non-judgmental, encouraging. Prefer clear, plain language over jargon.\(contextNotes)

        Core behavior:
        - Interpret inputs (text, images, check-ins, meds, sleep, hydration) to infer patterns and likely contributors.
        - If health data is available (steps, heart rate, sleep, calories), reference it naturally in your responses.
        - Offer concise next steps: hydration, sleep hygiene, stress reduction, posture, nutrition, gentle activity.
        - Ask at most one brief follow-up (duration, severity 0–10, location, triggers, sleep, hydration, meds, stress).
        - Convert guidance into trackable actions or habits when helpful (e.g., hydration target, bedtime routine).
        - Teach briefly: one short explanation or tip that improves self-care confidence.

        Safety and escalation:
        - If red flags are described (e.g., severe chest pain, trouble breathing, one-sided weakness, stroke signs,
          severe dehydration, uncontrolled bleeding, suicidal thoughts), clearly recommend urgent evaluation now and
          remain supportive. Do not refuse reasoning; briefly explain why escalation matters.

        Output style (plain text, no em dashes, no headings):
        - Sound like a clinician texting. Short sentences, natural tone, 1–3 short paragraphs.
        - Use bullets only for steps when helpful; otherwise, write as normal chat.
        - Give specific quantities/timing when possible. Avoid jargon.
        - Do not present a diagnosis; frame as likely contributors and safe next steps.
        """
        // 1) Use Gemini API (only option)
        return await fetchGeminiReply(history: history, userInput: userInput, attachments: attachments, systemPrompt: system, apiKey: geminiKey)
    }
    
    // MARK: Gemini API call - SIMPLE, RELIABLE VERSION FROM SCRATCH
    private func fetchGeminiReply(history: [(role: String, content: String)], userInput: String, attachments: [Attachment], systemPrompt: String, apiKey: String) async -> String {
        
        // Simple error handler
        func showError(_ msg: String) async {
            await MainActor.run {
                banner(msg, error: true)
            }
        }
        
        // Build request URL - use v1beta with available model
        // Using lite model for better rate limits
        let model = "gemini-2.0-flash-lite-001"  // Lite model with potentially higher rate limits
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            await showError("invalid api url")
            return "I couldn't create the request. Please check your API key."
        }
        
        print("📤 PulseChat: Calling Gemini API - Model: \(model)")
        
        // Build contents array - must have at least one message
        var contents: [[String: Any]] = []
        
        // Add history messages
        for (role, content) in history {
            let geminiRole = (role == "assistant") ? "model" : "user"
            contents.append([
                "role": geminiRole,
                "parts": [
                    ["text": content]
                ]
            ])
        }
        
        // Build current user message
        var userParts: [[String: Any]] = []
        
        // Add text if present
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInput.isEmpty {
            userParts.append([
                "text": trimmedInput
            ])
        }
        
        // Add images if any
        for attachment in attachments {
            let image = attachment.image.downscaledIfNeeded(maxDimension: 768)
            if let jpegData = image.jpegData(compressionQuality: 0.7), jpegData.count < 1_000_000 {
                userParts.append([
                    "inline_data": [
                        "mime_type": "image/jpeg",
                        "data": jpegData.base64EncodedString()
                    ]
                ])
                print("📤 PulseChat: Added image (\(jpegData.count / 1024)KB)")
            }
        }
        
        // Add current user message to contents
        if !userParts.isEmpty {
            contents.append([
                "role": "user",
                "parts": userParts
            ])
        }
        
        // Ensure we have at least one message
        guard !contents.isEmpty else {
            await showError("no message content")
            return "Please provide a message or image."
        }
        
        // Build request body - v1 API format (systemInstruction supported in v1)
        var requestBody: [String: Any] = [
            "contents": contents
        ]
        
        // Add system instruction if provided (v1 API supports this)
        if !systemPrompt.isEmpty {
            requestBody["systemInstruction"] = [
                "parts": [
                    ["text": systemPrompt]
                ]
            ]
        }
        
        // Add generation config
        requestBody["generationConfig"] = [
            "temperature": 0.7,
            "maxOutputTokens": 1000
        ]
        
        // Encode JSON - use valid JSON encoding without pretty printing for API
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ PulseChat: JSON encoding error: \(error)")
            print("❌ PulseChat: Request body structure: \(requestBody)")
            await showError("failed to encode request: \(error.localizedDescription)")
            return "I couldn't prepare the request. Please try again."
        }
        
        // Debug: Print request structure for troubleshooting
        print("📤 PulseChat: Request size: \(jsonData.count) bytes, \(attachments.count) images")
        print("📤 PulseChat: Contents count: \(contents.count)")
        
        // Validate JSON is valid
        guard JSONSerialization.isValidJSONObject(requestBody) else {
            print("❌ PulseChat: Invalid JSON object structure")
            await showError("invalid request format")
            return "Invalid request format. Please try again."
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        // Make the call - SIMPLE, ONE ATTEMPT
        do {
            print("📤 PulseChat: Sending request...")
            let session = createGeminiSession()
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                await showError("invalid response")
                return "Received invalid response. Please try again."
            }
            
            print("📥 PulseChat: Response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "unknown error"
                print("❌ PulseChat: HTTP \(httpResponse.statusCode)")
                print("❌ PulseChat: Error body: \(errorBody)")
                
                // Parse error details from JSON response
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("❌ PulseChat: Error JSON: \(errorJson)")
                    
                    if let errorObj = errorJson["error"] as? [String: Any] {
                        let message = errorObj["message"] as? String ?? "unknown error"
                        let status = errorObj["status"] as? String ?? ""
                        
                        // Check for rate limit errors
                        if status == "RESOURCE_EXHAUSTED" || message.lowercased().contains("rate limit") {
                            await showError("rate limit exceeded")
                            return "You've reached the rate limit (200 requests/day). Please wait or try a different model."
                        }
                        
                        // Check for invalid JSON errors
                        if message.lowercased().contains("invalid json") || message.lowercased().contains("parse") {
                            await showError("invalid request format")
                            return "Invalid request format. The API couldn't parse the request. Please try again."
                        }
                        
                        await showError("\(httpResponse.statusCode): \(message)")
                        return "Error: \(message). Please try again."
                    }
                }
                
                // Handle specific status codes
                switch httpResponse.statusCode {
                case 429:
                    await showError("rate limit exceeded")
                    return "Rate limit exceeded. You've hit the daily limit. Please wait or try a different model."
                case 400:
                    await showError("bad request - invalid format")
                    return "Invalid request format. Please try again with a shorter message."
                default:
                    await showError("server error \(httpResponse.statusCode)")
                    return "Server error \(httpResponse.statusCode): \(errorBody.prefix(100)). Please try again."
                }
            }
            
            // Parse response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("❌ PulseChat: Invalid response format")
                await showError("invalid response format")
                return "I received an invalid response. Please try again."
            }
            
            let formatted = formatAIResponse(text.trimmingCharacters(in: .whitespacesAndNewlines))
            print("✅ PulseChat: Got response (\(formatted.count) chars)")
            return formatted
            
        } catch {
            print("❌ PulseChat: Error: \(error.localizedDescription)")
            
            // Simple error message
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    await showError("request timed out - check internet")
                    return "The request timed out. Please check your internet connection and try again."
                case .notConnectedToInternet:
                    await showError("no internet connection")
                    return "No internet connection. Please check your WiFi or cellular data."
                case .cannotConnectToHost:
                    await showError("cannot reach server")
                    return "Cannot reach the server. Please check your internet connection."
                default:
                    await showError("network error: \(urlError.localizedDescription)")
                    return "Network error: \(urlError.localizedDescription). Please try again."
                }
            }
            
            await showError("error: \(error.localizedDescription)")
            return "An error occurred: \(error.localizedDescription). Please try again."
        }
    }
    

    // MARK: OCR

    private func runOCR(on image: UIImage) async {
        guard let cg = image.cgImage else { return }
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .accurate
        req.usesLanguageCorrection = true
        req.minimumTextHeight = 0.02
        req.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        do {
            try handler.perform([req])
            let text = (req.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if !text.isEmpty {
                messages.append(ChatMessage(
                    text: "label text i found: “\(text.prefix(180))” — want me to set a schedule or verify a dose?",
                    isUser: false,
                    actions: [.logMed]
                ))
            } else {
                banner("i couldn’t read text from that photo — try a clearer, closer shot with good lighting.", error: true)
            }
        } catch {
            banner("ocr failed: \(error.localizedDescription)", error: true)
        }
    }

    // MARK: message actions & misc

    func handleInlineAction(_ action: InlineAction, source: ChatMessage) {
        switch action {
        case .addPlan: banner("added a habit idea to plan (stub).")
        case .followup6h: banner("scheduled a follow-up in ~6 hours (stub).")
        case .openLearn: banner("opened a learn module suggestion (stub).")
        case .logMed: banner("opened meds quick log (stub).")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }

    func copyMessage(_ msg: ChatMessage) {
        UIPasteboard.general.string = msg.text
        banner("copied.")
    }

    func editAndResend(_ msg: ChatMessage) {
        currentInput = msg.text
    }

    func toggleBookmark(_ msg: ChatMessage) {
        if let idx = messages.firstIndex(of: msg) {
            messages[idx].bookmarked.toggle()
            banner(messages[idx].bookmarked ? "bookmarked." : "bookmark removed.")
        }
    }

    func requestRecap() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let prompt = "summarize our chat into a short checklist of next steps with simple checkboxes."
            let reply = await self.fetchAIReply(history: self.recentHistory(), userInput: prompt, attachments: [])
            await self.streamReply(reply)
        }
    }

    func exportSession() {
        let md = messages.map { m in
            let who = m.isUser ? "You" : "Preventa"
            return "### \(who)\n\(m.text)\n"
        }.joined(separator: "\n")

        if let url = ReportExporter.export(markdown: md) {
            banner("exported to \(url.lastPathComponent)")
        } else {
            banner("export failed", error: true)
        }
    }


    func clearSession() {
        messages.removeAll()
        bootstrap()
        title = "new session"
        sessions[sessionId] = title
        banner("cleared.")
    }

    func loadSession(_ id: UUID) {
        guard id != sessionId else { return }
        // Stub — you can save/load from disk later
        messages.removeAll()
        messages.append(ChatMessage(text: "Loaded session: “\(sessions[id] ?? "untitled")”", isUser: false))
        banner("Session switched.")
    }

    func deleteSession(_ id: UUID) {
        sessions.removeValue(forKey: id)
        if id == sessionId {
            messages.removeAll()
            title = "new session"
            sessions[sessionId] = title
            banner("session reset.")
        }
    }

    func banner(_ text: String?, error: Bool = false) {
        bannerText = text
        bannerIsError = error
        if text != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
                if self?.bannerText == text { self?.bannerText = nil }
            }
        }
    }

    func openResources() { banner("opening resources… (stub)") }

    // Quick actions for tray
    func openJournal() {
        banner("opened journal (stub)")
    }
    func quickHydration() {
        banner("logged hydration (stub)")
    }
}

// MARK: - ui pieces

private struct TopBar: View {
    var title: String
    var medsDue: Int
    var checkinsDue: Int
    var streak: Int
    var onNew: () -> Void
    var onCloseDrawer: () -> Void
    var onExport: () -> Void
    var onDelete: () -> Void
    var onOpenTimeline: () -> Void   // 👈 new callback
    var onToggleFocus: () -> Void
    var focusEnabled: Bool


    var body: some View {
        HStack(spacing: 12) {
            // Left drawer toggle
            Button(action: onCloseDrawer) {
                Image(systemName: "sidebar.left")
                    .imageScale(.large)
                    .foregroundStyle(.white)
            }

            // Compact New button integrated in the bar
            Button(action: onNew) {
                Label("New", systemImage: "plus")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Brand.surfaceA, in: Capsule())
                    .overlay(Capsule().stroke(Brand.chipStroke))
                    .foregroundStyle(Brand.textPrimary)
            }

            Spacer()

            // Title
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            // Menu with actions
            Menu {
                Button("Export", action: onExport)
                Button("Delete", action: onDelete)
                Divider()
                Button("Open Timeline", action: onOpenTimeline)
                Button(focusEnabled ? "Exit Focus Mode" : "Enter Focus Mode", action: onToggleFocus)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 6)
    }
}
private struct TodayPulseCard: View {
    var strip: TodayStrip

    var body: some View {
        HStack(spacing: 10) {
            StatChip(icon: "pills.fill",    label: "Meds",      value: "\(strip.medsDue)")
            StatChip(icon: "checkmark.seal",label: "Check-ins", value: "\(strip.checkinsDue)")
            StatChip(icon: "flame.fill",    label: "Streak",    value: "\(strip.streak)d")
        }
        .padding(12)
        .background(
            LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .foregroundStyle(.white)
    }
}

private struct StatChip: View {
    var icon: String
    var label: String
    var value: String

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.white.opacity(0.12))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .imageScale(.small)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2.weight(.medium)).opacity(0.9)
                Text(value).font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: Capsule()
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct SafetyBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cross.case").imageScale(.small)
            Text("I’m here to support education and self-care — not to diagnose. Seek urgent help for any red-flag symptoms.")
                .font(.caption)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(.white.opacity(0.95))
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.18), lineWidth: 1))
        .padding(.horizontal, 14)
    }
}

private struct RedFlagBanner: View {
    let text: String
    var onResources: () -> Void
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .font(.footnote.weight(.semibold))
                .lineLimit(2)
            Spacer()
            Button("resources", action: onResources)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(
            LinearGradient(colors: [.red.opacity(0.75), .orange.opacity(0.75)],
                           startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2), lineWidth: 1))
        .scaleEffect(pulse ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityHint("Urgent health notice")
    }
}

private struct Banner: View {
    let text: String
    var isError: Bool
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "wifi.exclamationmark" : "checkmark.circle")
            Text(text).font(.caption.weight(.semibold))
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

private struct MessageRow: View {
    let message: ChatMessage
    var onCopy: () -> Void
    var onEditResend: () -> Void
    var onBookmark: () -> Void
    var onAddPlan: () -> Void
    var onStartFollowup: () -> Void
    var onOpenLearn: () -> Void
    var onLogMed: () -> Void
    var speak: () -> Void

    @State private var showReactions = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 12) {
                if !message.isUser {
                    ModernAvatar(kind: .ai)
                }

                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                    Group {
                        if message.text == "…" && !message.isUser {
                            ModernTypingIndicator()
                        } else {
                            ModernTextRenderer(message: message.text)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(modernBubbleBackground(isUser: message.isUser))
                    .shadow(
                        color: message.isUser 
                            ? Color.blue.opacity(0.3) 
                            : Color.black.opacity(0.15),
                        radius: message.isUser ? 12 : 8,
                        y: message.isUser ? 6 : 4
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: 520, alignment: message.isUser ? .trailing : .leading)
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .onTapGesture(count: 2) { 
                        withAnimation(.spring(response: 0.3)) {
                            showReactions.toggle()
                        }
                    }
                    .onLongPressGesture {
                        // Show context menu on long press
                    }
                    .contextMenu {
                        Button {
                            onCopy()
                            Hx.ok()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Button {
                            onEditResend()
                            Hx.tap()
                        } label: {
                            Label("Edit & Resend", systemImage: "pencil")
                        }
                        Button {
                            onBookmark()
                            Hx.tap()
                        } label: {
                            Label(
                                message.bookmarked ? "Remove Bookmark" : "Bookmark",
                                systemImage: message.bookmarked ? "bookmark.fill" : "bookmark"
                            )
                        }
                    }

                    if let c = message.confidenceNote, !message.isUser {
                        ModernConfidenceMeter(note: c)
                    }

                    if !message.attachments.isEmpty {
                        AttachmentPreviewRowStatic(items: message.attachments)
                    }

                    if !message.isUser && !message.actions.isEmpty {
                        ModernInlineActionRow(
                            actions: message.actions,
                            onAddPlan: onAddPlan,
                            onFollowup: onStartFollowup,
                            onOpenLearn: onOpenLearn,
                            onLogMed: onLogMed,
                            onSpeak: speak
                        )
                    }
                }

                if message.isUser {
                    ModernAvatar(kind: .user)
                }
            }

            if showReactions {
                ModernReactionsRow(
                    onBookmark: onBookmark,
                    onSpeak: speak,
                    isBookmarked: message.bookmarked
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: message.bookmarked)
        .transition(.asymmetric(
            insertion: .move(edge: message.isUser ? .trailing : .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        ))
    }

    @ViewBuilder
    private func modernBubbleBackground(isUser: Bool) -> some View {
        if isUser {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.95),
                            Color.purple.opacity(0.95),
                            Color.indigo.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        }
    }
}
private enum AvatarKind { case ai, user }

private struct ModernAvatar: View {
    var kind: AvatarKind
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    kind == .ai
                        ? LinearGradient(
                            colors: [.purple.opacity(0.4), .blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.blue.opacity(0.3), .cyan.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .frame(width: 36, height: 36)
                .blur(radius: 4)
                .opacity(pulse ? 0.8 : 0.6)
                .scaleEffect(pulse ? 1.1 : 1.0)
            
            // Main circle
            Circle()
                .fill(
                    kind == .ai
                        ? LinearGradient(
                            colors: [
                                Color.purple.opacity(0.7),
                                Color.blue.opacity(0.7),
                                Color.indigo.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.blue.opacity(0.6),
                                Color.cyan.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            
            // Icon
            Image(systemName: kind == .ai ? "sparkles" : "person.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, value: pulse)
        }
        .onAppear {
            if kind == .ai {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}

private struct ModernReactionsRow: View {
    var onBookmark: () -> Void
    var onSpeak: () -> Void
    var isBookmarked: Bool
    @State private var tappedReaction: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ReactionButton(
                icon: "hand.thumbsup.fill",
                color: .blue,
                action: { tappedReaction = "thumbsup" }
            )
            ReactionButton(
                icon: "heart.fill",
                color: .pink,
                action: { tappedReaction = "heart" }
            )
            ReactionButton(
                icon: isBookmarked ? "bookmark.fill" : "bookmark",
                color: .yellow,
                action: {
                    onBookmark()
                    tappedReaction = "bookmark"
                }
            )
            ReactionButton(
                icon: "speaker.wave.2.fill",
                color: .green,
                action: {
                    onSpeak()
                    tappedReaction = "speaker"
                }
            )
        }
        .padding(.top, 4)
    }
}

private struct ReactionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: color.opacity(0.3), radius: 6, y: 3)
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

private struct ModernTypingIndicator: View {
    @State private var animate = false
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.75)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 8, height: 8)
                        .scaleEffect(animate ? 1.3 : 0.8)
                        .opacity(animate ? 1.0 : 0.5)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                            value: animate
                        )
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .blur(radius: 2)
                        .scaleEffect(animate ? 1.4 : 1.0)
                        .opacity(animate ? 0.6 : 0.3)
                        .animation(
                            .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                            value: animate
                        )
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear { 
            withAnimation {
                animate = true
            }
        }
        .accessibilityLabel("assistant is typing")
    }
}

private struct ModernConfidenceMeter: View {
    var note: String
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.yellow.opacity(0.9))
                    .frame(width: 6, height: 6)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 4)
            }
            Text(note)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct ModernTextRenderer: View {
    let message: String
    var body: some View {
        Group {
            if let md = try? AttributedString(markdown: message) { 
                Text(md)
            } else { 
                Text(message)
            }
        }
        .font(.system(size: 16, weight: .regular, design: .rounded))
        .multilineTextAlignment(.leading)
        .minimumScaleFactor(0.9)
        .lineLimit(nil)
        .textSelection(.enabled)
        .lineSpacing(2)
    }
}

private struct ModernInlineActionRow: View {
    let actions: [InlineAction]
    var onAddPlan: () -> Void
    var onFollowup: () -> Void
    var onOpenLearn: () -> Void
    var onLogMed: () -> Void
    var onSpeak: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(actions, id: \.self) { action in
                    ModernActionChip(
                        title: action.title,
                        icon: action.icon,
                        action: {
                            switch action {
                            case .addPlan: onAddPlan()
                            case .followup6h: onFollowup()
                            case .openLearn: onOpenLearn()
                            case .logMed: onLogMed()
                            }
                            Hx.tap()
                        }
                    )
                }
                ModernActionChip(
                    title: "Speak",
                    icon: "speaker.wave.2.fill",
                    action: {
                        onSpeak()
                        Hx.ok()
                    }
                )
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct ModernActionChip: View {
    var title: String
    var icon: String
    var action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

private struct RecapPill: View {
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle").imageScale(.small)
                Text("recap this chat").font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(LinearGradient(colors: [.blue.opacity(0.85), .purple.opacity(0.85)], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
}

private struct AttachmentTray: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Binding var selection: [PhotosPickerItem]
    var onCamera: () -> Void
    var onLibrary: () -> Void
    var onJournal: () -> Void
    var onHydration: () -> Void
    var onVoiceDown: () -> Void
    var onVoiceUp: () -> Void

    var body: some View {
        let compact = (hSizeClass == .compact)
        let columns = Array(repeating: GridItem(.flexible(minimum: 72), spacing: 12, alignment: .top), count: compact ? 3 : 5)

        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            PhotosPicker(selection: $selection, matching: .images) {
                TrayTile(icon: "photo.on.rectangle", title: "Photos")
            }

            Button(action: onCamera) {
                TrayTile(icon: "camera.fill", title: "Camera")
            }

            Button(action: onLibrary) {
                TrayTile(icon: "folder", title: "Library")
            }

            Button(action: onJournal) {
                TrayTile(icon: "checklist", title: "Journal")
            }

            Button(action: onHydration) {
                TrayTile(icon: "drop", title: "Hydration")
            }

            Button {} label: {
                TrayTile(icon: "waveform.circle.fill", title: "Talk")
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onVoiceDown() }
                    .onEnded { _ in onVoiceUp() }
            )
        }
        .padding(.vertical, 4)
        .foregroundStyle(.white)
    }
}

private struct TrayButton: View {
    var icon: String
    var title: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).imageScale(.medium)
            Text(title).font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

// Grid tile used in AttachmentTray for consistent layout
private struct TrayTile: View {
    var icon: String
    var title: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

private struct AttachmentPreviewRow: View {
    var items: [Attachment]
    var onNote: (UUID) -> Void
    var onMarkup: (UUID) -> Void
    var onRemove: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items) { att in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: att.image)
                            .resizable().scaledToFill()
                            .frame(width: 84, height: 84).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.22)))
                            .overlay(alignment: .bottomLeading) {
                                Text(att.kind.rawValue)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .padding(6)
                            }
                        HStack(spacing: 6) {
                            Button(action: { onNote(att.id) }) { Image(systemName: "note.text").imageScale(.small) }
                            Button(action: { onMarkup(att.id) }) { Image(systemName: "pencil.tip.crop.circle").imageScale(.small) }
                            Button(action: { onRemove(att.id) }) { Image(systemName: "xmark.circle.fill").imageScale(.small) }
                        }
                        .padding(6)
                        .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}

private struct AttachmentPreviewRowStatic: View {
    var items: [Attachment]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { att in
                    Image(uiImage: att.image)
                        .resizable().scaledToFill()
                        .frame(width: 68, height: 68).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.2)))
                        .accessibilityLabel("image attachment \(att.kind.rawValue)")
                }
            }
        }
    }
}

private struct BeforeAfterCompare: View {
    let pair: (UIImage, UIImage)
    @State private var pct: CGFloat = 0.5
    var body: some View {
        ZStack {
            Image(uiImage: pair.0).resizable().scaledToFill()
            Image(uiImage: pair.1).resizable().scaledToFill().mask(
                GeometryReader { geo in
                    Rectangle().frame(width: geo.size.width * pct)
                }
            )
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2)))
        .gesture(DragGesture().onChanged { pct = max(0, min(1, pct + $0.translation.width / 240)) })
        .accessibilityLabel("before and after compare slider")
    }
}

private struct ChipsStrip: View {
    @State private var expanded = false
    var contextChips: [String]
    var starterChips: [String]
    var onTap: (String) -> Void
    var onBodyMap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Shortcuts")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [Color.blue, Color.purple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing))
                }
            }

            if expanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(contextChips, id: \.self) { c in
                            ModernActionChip(title: c, icon: "sparkles", action: { onTap(c) })
                        }
                        ModernActionChip(title: "body map", icon: "figure.arms.open", action: onBodyMap)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(starterChips, id: \.self) { c in
                            ModernActionChip(title: c, icon: "bolt.heart", action: { onTap(c) })
                        }
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.top, 6)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.14), lineWidth: 1))
    }
}

private struct InputBar: View {
    @Binding var text: String
    var hasAttachments: Bool
    var sending: Bool
    @FocusState.Binding var isFocused: Bool
    var onSend: () -> Void
    var onTray: () -> Void
    var onPhoto: () -> Void
    var onCamera: () -> Void
    var onMicDown: () -> Void
    var onMicUp: () -> Void

    @State private var micPressed = false

    var disabledSend: Bool {
        (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasAttachments) || sending
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTray) {
                ModernCircleIcon(icon: "plus", color: .blue)
            }

            ZStack(alignment: .leading) {
                if text.isEmpty && !isFocused {
                    Text("Message Preventa Pulse...")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .accessibilityHidden(true)
                }

                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .submitLabel(.send)
                    .focused($isFocused)
                    .onSubmit { 
                        if !disabledSend { 
                            onSend()
                            Hx.ok()
                        } else {
                            Hx.warn()
                        }
                    }
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isFocused ? 0.18 : 0.12),
                                                Color.white.opacity(isFocused ? 0.08 : 0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isFocused ? 0.3 : 0.2),
                                                Color.white.opacity(isFocused ? 0.15 : 0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isFocused ? 2 : 1.5
                                    )
                            )
                    )
                    .shadow(
                        color: isFocused ? Color.blue.opacity(0.2) : Color.black.opacity(0.1),
                        radius: isFocused ? 12 : 8,
                        y: isFocused ? 6 : 4
                    )
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .accessibilityLabel("message field")
            }

            // Mic Button
            Button(action: {}) {
                ModernCircleIcon(
                    icon: micPressed ? "waveform" : "mic.fill",
                    color: micPressed ? .red : .green
                )
                .scaleEffect(micPressed ? 1.1 : 1.0)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in 
                        if !micPressed {
                            micPressed = true
                            onMicDown()
                        }
                    }
                    .onEnded { _ in 
                        if micPressed {
                            micPressed = false
                            onMicUp()
                        }
                    }
            )

            // Send Button
            Button(action: {
                onSend()
                Hx.ok()
            }) {
                ModernCircleIcon(
                    icon: sending ? "hourglass" : "arrow.up.circle.fill",
                    color: disabledSend ? .gray : .blue
                )
                .scaleEffect(sending ? 1.0 : (disabledSend ? 1.0 : 1.05))
            }
            .disabled(disabledSend)
            .accessibilityLabel("send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// Modern circular glass icon with enhanced design
private struct ModernCircleIcon: View {
    var icon: String
    var color: Color = .blue
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.4),
                            color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
                .blur(radius: 8)
                .opacity(isPressed ? 0.8 : 0.6)
            
            // Main circle
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: color.opacity(0.3),
                    radius: 8,
                    y: 4
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .contentShape(Circle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

private struct HistoryDrawer: View {
    var sessions: [UUID: String]
    var currentId: UUID
    var onSelect: (UUID) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chat History")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.top, 14)

            // 🔁 Fixed: Styled like all other buttons
            Button {
                let newId = UUID()
                onSelect(newId)   // delegate the creation logic upward
            } label: {
                Label("New Chat", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(LinearGradient(colors: [.blue.opacity(0.85), .purple.opacity(0.85)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Divider().background(.white.opacity(0.15)).padding(.vertical, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sessions.sorted(by: { $0.value < $1.value }), id: \.key) { id, title in
                        HStack {
                            Text(title.isEmpty ? "Untitled" : title)
                                .foregroundStyle(id == currentId ? .white : .white.opacity(0.85))
                                .font(.subheadline.weight(id == currentId ? .bold : .regular))
                                .lineLimit(1)

                            Spacer()

                            Button(role: .destructive) {
                                onDelete(id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .onTapGesture { onSelect(id) }
                    }
                }
                .padding(.bottom, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(Color.black) // Fully black background
    }
}

// MARK: - background

private struct PulseAnimatedBackground: View {
    @State private var phase: CGFloat = 0
    @AppStorage("ui.mood") private var mood: String = "neutral" // "calm", "neutral", "urgent"

    private var base: LinearGradient {
        switch mood {
        case "calm":
            return LinearGradient(colors: [Color.purple.opacity(0.85), Color.blue.opacity(0.9)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case "urgent":
            return LinearGradient(colors: [Color.purple.opacity(0.92), Color.red.opacity(0.65)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return Brand.grad
        }
    }

    var body: some View {
        base
            .overlay(
                AngularGradient(
                    gradient: Gradient(colors: [.white.opacity(0.08), .clear,
                                                .white.opacity(0.06), .clear]),
                    center: .center,
                    angle: .degrees(Double(phase))
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
            .accessibilityHidden(true)
    }
}

