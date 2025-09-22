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

    var body: some View {
        GeometryReader { geo in
            let drawerWidth = min(320, max(260, geo.size.width * 0.72))
            let columnWidth = min(720, geo.size.width) // Centered column on iPad, full width on iPhone

            ZStack(alignment: .leading) {
                PulseAnimatedBackground().ignoresSafeArea()
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded {          // tap background to dismiss
                        hideKeyboard()
                    })

                // ===== Main content as a centered column =====
                VStack(spacing: 0) {
                    TopBar(title: vm.title,
                           medsDue: vm.today.medsDue,
                           checkinsDue: vm.today.checkinsDue,
                           streak: vm.today.streak,
                           onCloseDrawer: { withAnimation(.spring()) { vm.historyOpen.toggle() } },
                           onExport: vm.exportSession,
                           onDelete: vm.clearSession)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .frame(maxWidth: columnWidth)

                    SafetyBanner()
                        .frame(maxWidth: columnWidth)

                    if let red = vm.redFlag {
                        RedFlagBanner(text: red, onResources: vm.openResources)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.horizontal, 14)
                            .padding(.top, 4)
                            .frame(maxWidth: columnWidth)
                    }

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
                        .simultaneousGesture(TapGesture().onEnded {   // tap content to dismiss
                            hideKeyboard()
                        })
                        .onChange(of: vm.messages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(vm.messages.last?.id, anchor: .bottom)
                            }
                        }
                    }

                    ChipsStrip(
                        contextChips: vm.contextChips,
                        starterChips: vm.starterChips,
                        onTap: { vm.insertChipAndSend($0) },
                        onBodyMap: { vm.startFromBodyMap() }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
                    .frame(maxWidth: columnWidth)

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
                    }

                    if let pair = vm.comparePair {
                        BeforeAfterCompare(pair: pair)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                            .transition(.opacity)
                            .frame(maxWidth: columnWidth)
                    }

                    if let banner = vm.bannerText {
                        Banner(text: banner, isError: vm.bannerIsError)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                            .frame(maxWidth: columnWidth)
                    }

                    // Input bar (aware of attachments so Send works even with only photos)
                    InputBar(
                        text: $vm.currentInput,
                        hasAttachments: !vm.attachments.isEmpty,
                        sending: vm.sending,
                        onSend: {
                            hideKeyboard()
                            vm.sendMessage()
                        },
                        onTray: {
                            hideKeyboard()        // collapse keyboard when opening tray
                            withAnimation(.spring()) { vm.showTray.toggle() }
                        },
                        onPhoto: { vm.pickFromLibrary = true },
                        onCamera: vm.openCamera,
                        onMicDown: vm.voiceDown,
                        onMicUp: vm.voiceUp
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.thinMaterial)
                    .frame(maxWidth: columnWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                // Dim when drawer is open; tap to close
                if vm.historyOpen {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) { vm.historyOpen = false }
                        }
                }

                // Drawer overlays instead of pushing content (prevents everything shifting right)
                HistoryDrawer(sessions: vm.sessions,
                              currentId: vm.sessionId,
                              onSelect: { vm.loadSession($0) },
                              onDelete: { vm.deleteSession($0) })
                    .frame(width: drawerWidth)
                    .offset(x: vm.historyOpen ? 0 : -drawerWidth - 20)
                    .transition(.move(edge: .leading))
                    .accessibilityHidden(!vm.historyOpen)
                    .shadow(radius: 12, y: 4)
            }
        }
        // === Overlay the tray in the safe-area (prevents layout blow-outs) ===
        .safeAreaInset(edge: .bottom) {
            if vm.showTray {
                AttachmentTray(
                    selection: $vm.photoItems,
                    onCamera: vm.openCamera,
                    onLibrary: { vm.pickFromLibrary = true },
                    onVoiceDown: vm.voiceDown,
                    onVoiceUp: vm.voiceUp,
                    keepLocal: $vm.keepLocalOnly,
                    blurFaces: $vm.blurFaces
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .overlay(Divider().background(.white.opacity(0.2)), alignment: .top)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .photosPicker(isPresented: $vm.pickFromLibrary, selection: $vm.photoItems, matching: .images)
        .onChange(of: vm.photoItems) { _, _ in vm.ingestPickedPhotos() } // iOS 17+ signature
        .onAppear { vm.bootstrap() }
        .navigationBarBackButtonHidden(false)
        .accessibilityElement(children: .contain)
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
    @Published var title: String = "preventa pulse"
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
            messages.append(ChatMessage(text: "hey, i’m preventa pulse. tell me what’s going on — or tap the tray to share a photo. i’ll ask quick follow-ups and suggest safe next steps.", isUser: false))
        }
        sessions[sessionId] = "new session"
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
        // SwiftUI doesn’t have a pure camera picker; surface library with Recents (works on device)
        pickFromLibrary = true
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
                let idx = (y*cg.bytesPerRow) + x*4
                b += Int(ptr[idx]); g += Int(ptr[idx+1]); r += Int(ptr[idx+2]); count += 1
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
            comparePair = (group[0].image, group[1].image)
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

            if title == "new session" || title == "preventa pulse",
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
            if let last = messages.last, !last.isUser, last.text != "…" {
                messages[messages.count - 1].text = buffer
            } else {
                messages.append(ChatMessage(text: buffer, isUser: false, actions: suggestedActions(for: buffer), confidenceNote: confidenceSuffix(for: buffer)))
            }
            try? await Task.sleep(nanoseconds: 12_000_000)
        }
        messages[messages.count - 1].actions = suggestedActions(for: text)
        messages[messages.count - 1].confidenceNote = confidenceSuffix(for: text)
        redFlag = detectRedFlags(text)
        if tokenDebug { banner("chars ~\(text.count)  •  context msgs \(min(messages.count, historyLimit))", error: false) }
    }

    private func suggestedActions(for text: String) -> [InlineAction] {
        var out: [InlineAction] = []
        let lower = text.lowercased()
        if lower.contains("habit") || lower.contains("plan") { out.append(.addPlan) }
        if lower.contains("check") || lower.contains("follow") { out.append(.followup6h) }
        if lower.contains("learn") || lower.contains("read") { out.append(.openLearn) }
        if lower.contains("med") || lower.contains("dose") { out.append(.logMed) }
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
                return fail("http \(e.status): \(e.body.prefix(200))")
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
            let text = req.results?
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

    func exportSession() { banner("exported as markdown/pdf (stub).") }

    func clearSession() {
        messages.removeAll()
        bootstrap()
        title = "new session"
        sessions[sessionId] = title
        banner("cleared.")
    }

    func loadSession(_ id: UUID) {
        withAnimation(.spring()) { historyOpen = false }
    }

    func deleteSession(_ id: UUID) { sessions.removeValue(forKey: id) }

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

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onCloseDrawer) {
                Image(systemName: "sidebar.leading")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title.isEmpty ? "preventa pulse" : title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            TodayStripView(medsDue: medsDue, checkinsDue: checkinsDue, streak: streak)

            Menu {
                Button("export", action: onExport)
                Button("delete session", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

private struct TodayStripView: View {
    var medsDue: Int
    var checkinsDue: Int
    var streak: Int
    var body: some View {
        HStack(spacing: 8) {
            Label("\(medsDue)", systemImage: "pills.fill")
            Label("\(checkinsDue)", systemImage: "checkmark.circle.fill")
            Label("\(streak)", systemImage: "flame.fill")
        }
        .font(.caption2.weight(.semibold))
        .labelStyle(.iconOnly)
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

private struct SafetyBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cross.case").imageScale(.small)
            Text("i’m here for education + self-care — not a diagnosis. get urgent help for red-flag symptoms.")
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
        .background(LinearGradient(colors: [.red.opacity(0.7), .orange.opacity(0.7)], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2), lineWidth: 1))
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

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.isUser { Spacer() }
                TextRenderer(message: message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground(isUser: message.isUser))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.18), .clear],
                                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 520, alignment: message.isUser ? .trailing : .leading) // sane bubble width on iPad
                    .contextMenu {
                        Button("copy", action: onCopy)
                        Button("edit & resend", action: onEditResend)
                        Button(message.bookmarked ? "remove bookmark" : "bookmark", action: onBookmark)
                    }
                    .accessibilityLabel(message.text)
                if !message.isUser { Spacer() }
            }

            if !message.attachments.isEmpty {
                AttachmentPreviewRowStatic(items: message.attachments)
            }

            if let c = message.confidenceNote, !message.isUser {
                Text(c).font(.caption2).foregroundStyle(.white.opacity(0.9))
            }

            if !message.isUser && !message.actions.isEmpty {
                InlineActionRow(actions: message.actions,
                                onAddPlan: onAddPlan,
                                onFollowup: onStartFollowup,
                                onOpenLearn: onOpenLearn,
                                onLogMed: onLogMed,
                                onSpeak: speak)
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
                ChipButton(title: "speak reply", icon: "speaker.wave.2.fill", action: onSpeak)
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
    @Binding var keepLocal: Bool
    @Binding var blurFaces: Bool

    var body: some View {
        let compact = (hSizeClass == .compact)
        VStack(spacing: 10) {
            // Row 1: primary actions
            HStack(spacing: 10) {
                PhotosPicker(selection: $selection, matching: .images) {
                    TrayButton(icon: "photo.on.rectangle", title: "photos")
                        .frame(minWidth: 0, maxWidth: compact ? .infinity : nil)
                }
                Button(action: onCamera) {
                    TrayButton(icon: "camera.fill", title: "camera")
                        .frame(minWidth: 0, maxWidth: compact ? .infinity : nil)
                }
                Button(action: onLibrary) {
                    TrayButton(icon: "folder", title: "library")
                        .frame(minWidth: 0, maxWidth: compact ? .infinity : nil)
                }
                if !compact { Spacer(minLength: 8) }
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.circle.fill").imageScale(.medium)
                        Text("hold to talk").font(.caption.weight(.semibold))
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

            // Row 2: options (wraps nicely on compact)
            HStack(spacing: 12) {
                Toggle(isOn: $keepLocal) { Text("keep local").font(.caption2) }
                    .toggleStyle(SwitchToggleStyle(tint: .white))
                Toggle(isOn: $blurFaces) { Text("blur").font(.caption2) }
                    .toggleStyle(SwitchToggleStyle(tint: .white))
                Spacer(minLength: 0)
            }
            .opacity(0.95)
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
    var contextChips: [String]
    var starterChips: [String]
    var onTap: (String) -> Void
    var onBodyMap: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(contextChips, id: \.self) { c in ChipButton(title: c, icon: "sparkles", action: { onTap(c) }) }
                    Button(action: onBodyMap) { ChipButton(title: "body map", icon: "figure.arms.open", action: onBodyMap) }
                        .buttonStyle(.plain)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(starterChips, id: \.self) { c in ChipButton(title: c, icon: "bolt.heart", action: { onTap(c) }) }
                }
            }
        }
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
                Image(systemName: "plus.circle").font(.system(size: 26, weight: .semibold))
            }
            .foregroundStyle(.white)

            // Return key sends; toolbar provides explicit "Send" button on keyboard as fallback
            TextField("message preventa pulse…", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit {
                    if !disabledSend { onSend() }
                }
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.18), lineWidth: 1))
                .foregroundStyle(.white)
                .font(.system(.body, design: .rounded))
                .accessibilityLabel("message field")
                .toolbar {                                  // iOS 15+; shows above keyboard
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Send") { onSend() }
                            .disabled(disabledSend)
                    }
                }

            Button {} label: { Image(systemName: "mic.fill").font(.system(size: 22, weight: .semibold)) }
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in onMicDown() }.onEnded { _ in onMicUp() })
                .foregroundStyle(.white)

            Button(action: onSend) {
                Image(systemName: sending ? "hourglass" : "arrow.up.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
            }
            .disabled(disabledSend)
            .accessibilityLabel("send")
        }
        .foregroundStyle(.white)
    }
}

private struct HistoryDrawer: View {
    var sessions: [UUID: String]
    var currentId: UUID
    var onSelect: (UUID) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("history").font(.headline).foregroundStyle(.white).padding(.top, 14)
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sessions.sorted(by: { $0.value < $1.value }), id: \.key) { id, title in
                        HStack {
                            Text(title.isEmpty ? "untitled" : title)
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
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onTapGesture { onSelect(id) }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .background(.thinMaterial)
    }
}

// MARK: - background

private struct PulseAnimatedBackground: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        LinearGradient(colors: [Color.purple.opacity(0.92), Color.blue.opacity(0.86)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                AngularGradient(gradient: Gradient(colors: [.white.opacity(0.08), .clear, .white.opacity(0.06), .clear]),
                                center: .center,
                                angle: .degrees(Double(phase)))
            )
            .onAppear {
                withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) { phase = 360 }
            }
    }
}
