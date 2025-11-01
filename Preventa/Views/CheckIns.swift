//
//  CheckIns.swift
//  Preventa
//
//  Created by Ojas Sarada on 10/3/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CheckInsView: View {
    @StateObject private var vm = CheckInsVM()
    @State private var showingNewCheckIn = false

    var body: some View {
        ZStack {
            AnimatedBrandBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header

                    if vm.checkIns.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        ForEach(vm.checkIns) { checkIn in
                            CheckInCard(checkIn: checkIn)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 80)
            }

            // Floating + button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Hx.tap()
                        showingNewCheckIn = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Check-Ins")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewCheckIn) {
            NewCheckInView { newCheckIn in
                vm.addCheckIn(newCheckIn)
            }
        }
        .onAppear { vm.loadCheckIns() }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Daily Check-Ins")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Text("Track your reflections, mood, and progress.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.7))
            Text("No check-ins yet")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Text("Start logging your thoughts and progress with the + button.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Card
private struct CheckInCard: View {
    let checkIn: CheckIn

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(checkIn.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(checkIn.dateString)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(checkIn.notes)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - New Check-In Sheet
private struct NewCheckInView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var mood: Double = 3 // 1 = bad, 5 = great

    var onSave: (CheckIn) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBrandBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(spacing: 16) {
                                // Title Field
                                TextField("", text: $title)
                                    .padding(10)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                                    .font(.headline)
                                    .placeholder(when: title.isEmpty) {
                                        Text("Enter a title")
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.leading, 4)
                                    }

                                // Notes Field
                                ZStack(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Write your thoughts...")
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 12)
                                    }
                                    TextEditor(text: $notes)
                                        .frame(height: 140)
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                // Mood Slider
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Mood")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.9))
                                    Slider(value: $mood, in: 1...5, step: 1)
                                        .tint(.purple)
                                    HStack {
                                        Text("☹️").opacity(mood == 1 ? 1 : 0.5)
                                        Spacer()
                                        Text("🙂").opacity(mood == 3 ? 1 : 0.5)
                                        Spacer()
                                        Text("😃").opacity(mood == 5 ? 1 : 0.5)
                                    }
                                    .font(.title2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newCheckIn = CheckIn(
                            id: UUID().uuidString,
                            title: title.isEmpty ? "Untitled" : title,
                            notes: notes,
                            mood: Int(mood),
                            timestamp: Date()
                        )
                        onSave(newCheckIn)
                        
                        // Generate AI response to check-in
                        // Removed AI check-in response to save API usage
                        
                        dismiss()
                    }
                    .disabled(title.isEmpty && notes.isEmpty)
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("New Check-In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Model
struct CheckIn: Identifiable {
    let id: String
    let title: String
    let notes: String
    let mood: Int
    let timestamp: Date

    var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, h:mm a"
        return fmt.string(from: timestamp)
    }
}

// MARK: - ViewModel
final class CheckInsVM: ObservableObject {
    @Published var checkIns: [CheckIn] = []

    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }

    func loadCheckIns() {
        guard let uid else { return }
        db.collection("users").document(uid).collection("checkIns")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self.checkIns = docs.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let notes = data["notes"] as? String,
                          let mood = data["mood"] as? Int,
                          let ts = data["timestamp"] as? Timestamp else { return nil }
                    return CheckIn(id: doc.documentID,
                                   title: title,
                                   notes: notes,
                                   mood: mood,
                                   timestamp: ts.dateValue())
                }
            }
    }

    func addCheckIn(_ checkIn: CheckIn) {
        guard let uid else { return }
        db.collection("users").document(uid).collection("checkIns")
            .document(checkIn.id)
            .setData([
                "title": checkIn.title,
                "notes": checkIn.notes,
                "mood": checkIn.mood,
                "timestamp": checkIn.timestamp
            ])
    }

}

// MARK: - Shared UI
struct AnimatedBrandBackground: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        LinearGradient(
            colors: [Color.purple.opacity(0.92), Color.blue.opacity(0.86)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            AngularGradient(
                gradient: Gradient(colors: [.white.opacity(0.08), .clear, .white.opacity(0.06), .clear]),
                center: .center,
                angle: .degrees(Double(phase))
            )
        )
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                phase = 360
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let expand: Bool
    let content: Content
    init(expand: Bool = true, @ViewBuilder content: () -> Content) {
        self.expand = expand
        self.content = content()
    }
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: expand ? .infinity : nil, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}
