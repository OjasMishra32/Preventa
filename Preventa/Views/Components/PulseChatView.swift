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

    var body: some View {
        GeometryReader { geo in
            let drawerWidth = min(320, max(260, geo.size.width * 0.72))
            let columnWidth = min(720, geo.size.width) // Centered column on iPad, full width on iPhone

            ZStack(alignment: .leading) {
                PulseAnimatedBackground().ignoresSafeArea()
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })

                VStack(spacing: 0) {
                    // === Session Tabs ===
                    SessionTabs(
                        sessions: vm.sessions,
                        currentId: vm.sessionId,
                        onNew: { vm.historyOpen = false; vm.clearSession() },
                        onSelect: { vm.loadSession($0) },
                        onRename: { id, title in vm.sessions[id] = title }
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .frame(maxWidth: columnWidth)
                    .opacity(focus ? 0 : 1)
                    .allowsHitTesting(!focus)

                    // === Top Bar ===
                    TopBar(
                        title: vm.title,
                        medsDue: vm.today.medsDue,
                        checkinsDue: vm.today.checkinsDue,
                        streak: vm.today.streak,
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

                    // === Today Pulse Card ===
                    TodayPulseCard(strip: vm.today)
                        .frame(maxWidth: columnWidth)
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                        .opacity(focus ? 0 : 1)
                        .allowsHitTesting(!focus)

                    // === Safety Banner ===
                    SafetyBanner()
                        .frame(maxWidth: columnWidth)
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

                    // === Input Bar (always visible, even in focus mode) ===
                    InputBar(
                        text: $vm.currentInput,
                        hasAttachments: !vm.attachments.isEmpty,
                        sending: vm.sending,
                        onSend: {
                            hideKeyboard()
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
                    .background(Color.black.opacity(0.6))
                    .frame(maxWidth: columnWidth)
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
            if vm.showTray {
                AttachmentTray(
                    selection: $vm.photoItems,
                    onCamera: vm.openCamera,
                    onLibrary: { vm.pickFromLibrary = true },
                    onVoiceDown: vm.voiceDown,
                    onVoiceUp: vm.voiceUp
                )
                .padding(.horizontal, 9)
                .padding(.top, 6)
                .padding(.bottom, 6)
                .background(Color.black.opacity(0.7))
                .overlay(Divider().background(.white.opacity(0.2)), alignment: .top)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
        guard maxSide > maxDimension, maxSide > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized ?? self
    }
}

// MARK: - view model

@MainActor
final class PulseChatVM: ObservableObject {

    // state
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var sending: Bool = false
    

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
            messages.append(ChatMessage(text: "Hi, I’m Preventa Pulse. Tell me what’s going on — or tap the tray to share a photo. I’ll ask quick follow-ups and suggest safe next steps.", isUser: false))
        }
        sessions[sessionId] = "New Session"
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
        Task {
            var fresh: [Attachment] = []

            for item in photoItems {
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

                guard let base = ui else {
                    banner("couldn’t read that photo (format/permissions). try another or re-grant Photos access in Settings.", error: true)
                    continue
                }

                // Normalize + downscale
                let image = base.fixedOrientation().downscaledIfNeeded(maxDimension: 2000)
                let clean = keepLocalOnly ? image : stripEXIF(image)
                let kind = autoCategorize(image: clean)

                fresh.append(Attachment(image: clean, kind: kind, keptLocal: keepLocalOnly, blurredFaces: blurFaces))
            }

            if !fresh.isEmpty {
                attachments.append(contentsOf: fresh)
                autoCompareCandidate()
                autoSuggestFromAttachments(fresh)
            }
            photoItems.removeAll()
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

    private func stripEXIF(_ image: UIImage) -> UIImage {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return image }
        return UIImage(data: data) ?? image
    }

    private func autoCategorize(image: UIImage) -> Attachment.Kind {
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

        let userMsg = ChatMessage(text: trimmed.isEmpty ? "[shared photo]" : trimmed, isUser: true, attachments: attachments)
        messages.append(userMsg)
        currentInput = ""
        attachments.removeAll()
        comparePair = nil

        let typingId = UUID()
        messages.append(ChatMessage(id: typingId, text: "…", isUser: false))

        sending = true
        banner(nil)

        Task {
            let reply = await fetchAIReply(history: recentHistory(), userInput: userMsg.text)
            if let idx = messages.firstIndex(where: { $0.id == typingId }) {
                messages.remove(at: idx)
            }
            await streamReply(reply)

            if title.lowercased() == "new session" || title.lowercased() == "preventa pulse",
               let first = messages.first(where: { $0.isUser })?.text {
                let compact = first.lowercased().prefix(30)
                title = String(compact)
                sessions[sessionId] = title
            }

            sending = false
        }
    }

    private func recentHistory() -> [(role: String, content: String)] {
        let last = Array(messages.suffix(historyLimit))
        return last.map { (role: $0.isUser ? "user" : "assistant", content: $0.text) }
    }

    private func streamReply(_ text: String) async {
        var buffer = ""
        for ch in text {
            buffer.append(ch)
            if let lastIdx = messages.indices.last,
               !messages[lastIdx].isUser {
                messages[lastIdx].text = buffer
            } else {
                messages.append(ChatMessage(text: buffer, isUser: false,
                    actions: suggestedActions(for: buffer),
                    confidenceNote: confidenceSuffix(for: buffer)))
            }
            try? await Task.sleep(nanoseconds: 12_000_000)
        }
        messages[messages.count - 1].actions = suggestedActions(for: text)
        messages[messages.count - 1].confidenceNote = confidenceSuffix(for: text)

        // 🔴 Red-flag detection + mood update
        redFlag = detectRedFlags(text)
        if redFlag != nil {
            UserDefaults.standard.setValue("urgent", forKey: "ui.mood")
        } else {
            UserDefaults.standard.setValue("neutral", forKey: "ui.mood")
        }

        if tokenDebug {
            banner("chars ~\(text.count)  •  context msgs \(min(messages.count, historyLimit))", error: false)
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

    // MARK: ai call — OpenRouter (sk-or- keys) with robust parsing + clear error banners
    private func fetchAIReply(history: [(role: String, content: String)], userInput: String) async -> String {
        struct HTTPError: Error { let status: Int; let body: String }
        func fail(_ msg: String) -> String { banner(msg, error: true); return "hmm, that didn’t come through. mind trying again?" }

        // 0) API key
        guard let rawKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !rawKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fail("i can’t find my api key (Info.plist → OPENAI_API_KEY).")
        }
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.hasPrefix("sk-or-") else {
            return fail("this build expects an OpenRouter key (sk-or-…). your key doesn’t look like one.")
        }

        // 1) Messages
        let system =
        """
        You are “Preventa Pulse,” a proactive health companion. Be warm, concise, practical.
        Focus on prevention, lifestyle, education, and safe guidance. Do not diagnose.
        Ask at most one short follow-up (duration, 0–10 severity, triggers, sleep, hydration, meds, stress).
        Propose micro-habits, trackable steps, and when to escalate; include warning signs to watch for.
        If red flags appear (severe chest pain, trouble breathing, stroke signs, suicidal thoughts),
        clearly advise immediate emergency help and be supportive. Keep answers under ~6 lines with short lists.
        """
        var msgs: [[String: Any]] = [["role": "system", "content": system]]
        for (role, content) in history { msgs.append(["role": role, "content": content]) }
        msgs.append(["role": "user", "content": userInput])

        // 2) OpenRouter endpoint + model (vendor-qualified)
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        let model = "openai/gpt-4o-mini"

        let body: [String: Any] = [
            "model": model,
            "messages": msgs,
            "max_tokens": 350,
            "temperature": 0.7
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = data
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            // Optional but recommended by OpenRouter
            req.setValue("https://preventa.app", forHTTPHeaderField: "HTTP-Referer")
            req.setValue("Preventa Pulse", forHTTPHeaderField: "X-Title")

            let (respData, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let bodyStr = String(data: respData, encoding: .utf8) ?? ""
                throw HTTPError(status: http.statusCode, body: bodyStr)
            }

            // Parse response (supports OpenRouter/OpenAI-style shapes)
            guard let root = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
                  let choices = root["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any] else {
                return fail("ai response not in expected format.")
            }

            // A) Plain string content
            if let s = message["content"] as? String,
               !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return s.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // B) Array-of-parts content
            if let parts = message["content"] as? [[String: Any]] {
                let texts = parts.compactMap { p -> String? in
                    if (p["type"] as? String) == "text" { return p["text"] as? String }
                    return nil
                }
                let joined = texts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !joined.isEmpty { return joined }
            }

            return fail("ai response empty — try again.")

        } catch let e as HTTPError {
            switch e.status {
            case 401: return fail("unauthorized (401): check your openrouter key (sk-or-…).")
            case 403: return fail("forbidden (403): key lacks access to \(model).")
            case 429: return fail("rate limit (429): too many requests or out of quota.")
            default:
                return fail("http \(e.status): \(String(e.body.prefix(200)))")
            }
        } catch {
            return fail("network/json error: \(error.localizedDescription)")
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
        Task {
            let prompt = "summarize our chat into a short checklist of next steps with simple checkboxes."
            let reply = await fetchAIReply(history: recentHistory(), userInput: prompt)
            await streamReply(reply)
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
}

// MARK: - ui pieces

private struct TopBar: View {
    var title: String
    var medsDue: Int
    var checkinsDue: Int
    var streak: Int
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
        HStack(spacing: 12) {
            MetricPill(icon: "pills", title: "Meds", value: "\(strip.medsDue)")
            MetricPill(icon: "heart.text.square", title: "Check-ins", value: "\(strip.checkinsDue)")
            MetricPill(icon: "flame", title: "Streak", value: "\(strip.streak)d")
        }
        .padding(12)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2)))
        .foregroundStyle(.white)
    }
}

private struct MetricPill: View {
    var icon: String
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).imageScale(.medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption2).opacity(0.9)
                Text(value).font(.headline.weight(.semibold))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.2)))
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

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                if !message.isUser {
                    Avatar(kind: .ai)
                }

                VStack(alignment: .leading, spacing: 6) {
                    TextRenderer(message: message.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleBackground(isUser: message.isUser))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(LinearGradient(
                                    colors: [.white.opacity(0.18), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                        .frame(maxWidth: 520, alignment: message.isUser ? .trailing : .leading)
                        .onTapGesture(count: 2) { showReactions.toggle() }
                        .contextMenu {
                            Button("copy", action: onCopy)
                            Button("edit & resend", action: onEditResend)
                            Button(message.bookmarked ? "remove bookmark" : "bookmark", action: onBookmark)
                        }

                    if let c = message.confidenceNote, !message.isUser {
                        ConfidenceMeter(note: c)
                    }

                    if !message.attachments.isEmpty {
                        AttachmentPreviewRowStatic(items: message.attachments)
                    }

                    if !message.isUser && !message.actions.isEmpty {
                        InlineActionRow(
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
                    Avatar(kind: .user)
                }
            }

            if showReactions {
                HStack(spacing: 10) {
                    Reaction("hand.thumbsup")
                    Reaction("heart.fill")
                    Reaction("bookmark.fill", action: onBookmark)
                    Reaction("speaker.wave.2.fill", action: speak)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message.bookmarked)
    }

    @ViewBuilder
    private func bubbleBackground(isUser: Bool) -> some View {
        if isUser {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [.blue.opacity(0.88), .purple.opacity(0.88)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.22), radius: 5, y: 3)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
        }
    }
}
private enum AvatarKind { case ai, user }

private struct Avatar: View {
    var kind: AvatarKind
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.08))
            Image(systemName: kind == .ai ? "sparkles" : "person.crop.circle.fill")
                .imageScale(.medium)
                .foregroundStyle(.white)
        }
        .frame(width: 28, height: 28)
        .overlay(Circle().stroke(Color.white.opacity(0.2)))
    }
}

private struct Reaction: View {
    var systemName: String
    var action: (() -> Void)? = nil
    init(_ name: String, action: (() -> Void)? = nil) {
        self.systemName = name
        self.action = action
    }

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemName).imageScale(.medium)
                .padding(6)
                .background(Color.white.opacity(0.06), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

private struct ConfidenceMeter: View {
    var note: String
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.yellow.opacity(0.9))
                .frame(width: 42, height: 4)
            Text(note)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

private struct TextRenderer: View {
    let message: String
    var body: some View {
        Group {
            if let md = try? AttributedString(markdown: message) { Text(md) } else { Text(message) }
        }
        .font(.system(.body, design: .rounded))
        .multilineTextAlignment(.leading)
        .minimumScaleFactor(0.9)
        .lineLimit(nil)
        .textSelection(.enabled)
    }
}

private struct InlineActionRow: View {
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
                    switch action {
                    case .addPlan: ChipButton(title: action.title, icon: action.icon, action: onAddPlan)
                    case .followup6h: ChipButton(title: action.title, icon: action.icon, action: onFollowup)
                    case .openLearn: ChipButton(title: action.title, icon: action.icon, action: onOpenLearn)
                    case .logMed: ChipButton(title: action.title, icon: action.icon, action: onLogMed)
                    }
                }
                ChipButton(title: "Speak Reply", icon: "speaker.wave.2.fill", action: onSpeak)
            }
        }
    }
}

private struct ChipButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).imageScale(.small)
                Text(title).font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
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
    var onVoiceDown: () -> Void
    var onVoiceUp: () -> Void

    var body: some View {
        let compact = (hSizeClass == .compact)
        VStack(spacing: 10) {
            // Row 1: primary actions
            HStack(spacing: 10) {
                PhotosPicker(selection: $selection, matching: .images) {
                    TrayButton(icon: "photo.on.rectangle", title: "Photos")
                        .frame(minWidth: 0, maxWidth: compact ? .infinity : nil)
                }
                Button(action: onCamera) {
                    TrayButton(icon: "camera.fill", title: "Camera")
                        .frame(minWidth: 0, maxWidth: compact ? .infinity : nil)
                }
                Button(action: onLibrary) {
                    TrayButton(icon: "folder", title: "Library")
                        .frame(minWidth: 0, maxWidth: compact ? .infinity : nil)
                }
                Button {} label: {
                    TrayButton(icon: "checklist", title: "Journal")
                }
                Button {} label: {
                    TrayButton(icon: "drop", title: "Hydration")
                }
                
                if !compact { Spacer(minLength: 8) }
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.circle.fill").imageScale(.medium)
                        Text("Talk").font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 0.8))
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in onVoiceDown() }
                        .onEnded { _ in onVoiceUp() }
                )
            }
        }
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
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
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
                    HStack(spacing: 10) {
                        ForEach(contextChips, id: \.self) { c in
                            ChipButton(title: c, icon: "sparkles", action: { onTap(c) })
                        }
                        ChipButton(title: "body map", icon: "figure.arms.open", action: onBodyMap)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(starterChips, id: \.self) { c in
                            ChipButton(title: c, icon: "bolt.heart", action: { onTap(c) })
                        }
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.top, 6)
    }
}

private struct InputBar: View {
    @Binding var text: String
    var hasAttachments: Bool
    var sending: Bool
    var onSend: () -> Void
    var onTray: () -> Void
    var onPhoto: () -> Void
    var onCamera: () -> Void
    var onMicDown: () -> Void
    var onMicUp: () -> Void

    var disabledSend: Bool {
        (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasAttachments) || sending
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTray) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Message Preventa Pulse")
                        .foregroundColor(.white.opacity(0.62))
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .accessibilityHidden(true)
                }

                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...4) // grows with content
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .submitLabel(.send)
                    .onSubmit { if !disabledSend { onSend() } }
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .font(.system(.body, design: .rounded))
                    .accessibilityLabel("message field")
            }



            // Mic Button (with long press for voice input)
            Button(action: {}, label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            })
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .onChanged { _ in onMicDown() }
                    .onEnded { _ in onMicUp() }
            )

            // Send Button (only one!)
            Button(action: onSend) {
                Image(systemName: sending ? "hourglass" : "arrow.up.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
            }
            .disabled(disabledSend)
            .accessibilityLabel("send")
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8) // ✅ Reduced padding
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
