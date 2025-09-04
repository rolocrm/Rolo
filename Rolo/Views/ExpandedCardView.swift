import SwiftUI

// MARK: - Card Protocol
protocol ExpandableCard {
    var id: UUID { get }
    var title: String { get }
    var date: Date { get }
    var type: CardType { get }
    var image: String { get }
    var isCompleted: Bool { get }
    func expandedView() -> AnyView
}

// MARK: - Base Card Model
struct BaseCard: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let image: String
    let type: CardType
    let isCompleted: Bool
}

// MARK: - Expanded Card Container View
struct ExpandedCardView: View {
    let card: any ExpandableCard
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onRemove: () -> Void
    let onSkip: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingProfile: Bool = false
    @State private var showingSnooze: Bool = false
    @State private var showingEdit: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack (spacing: 24) {
                            // Profile Navigation
                            HStack {
                                VStack {
                                    Button(action: { dismiss() }) {
                                        Image(systemName: "arrow.left")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(GlobalTheme.roloLight)
                                            .padding(8)
                                            .contentShape(Rectangle())
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(){
                                    Menu {
                                        Button(action: { showingProfile = true }) {
                                            Label("View profile", systemImage: "person.circle")
                                        }
                                        
                                        Button(action: { showingSnooze = true }) {
                                            Label("Snooze task", systemImage: "clock")
                                        }
                                        
                                        Button(action: {}) {
                                            Label("Remove Priority", systemImage: "star.slash")
                                        }
                                        
                                        Button(action: { showingEdit = true }) {
                                            Label("Edit template", systemImage: "pencil")
                                        }
                                        
                                        Button(action: {
                                            dismiss()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                onSkip()
                                            }
                                        }) {
                                            Label("Skip task", systemImage: "arrow.right")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            onRemove()
                                            onDelete()
                                            dismiss()
                                        }) {
                                            Label("Delete task", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(GlobalTheme.roloLight)
                                            .padding(8)
                                            .contentShape(Rectangle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack{
                                // Profile Photo
                                Image(card.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                
                            }
                            
                            // Info Section
                            VStack(spacing: 12) {
                                // Title
                                HStack {
                                    Spacer()
                                    Text(card.title)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(GlobalTheme.roloLight)
                                    Spacer()
                                }
                                
                                // Contact Buttons
                                HStack(spacing: 32) {
                                    Button(action: {}) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(GlobalTheme.highlightGreen)
                                    }
                                    
                                    Button(action: {}) {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(GlobalTheme.highlightGreen)
                                    }
                                    
                                    Button(action: {}) {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(GlobalTheme.highlightGreen)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                        
                        // Card-specific content
                        card.expandedView()
                            .padding()
                    }
                }
                
                // Mark Complete Button - Only show if not completed
                if !card.isCompleted {
                    VStack {
                        RoloBigButton(title: "Mark Complete", action: {
                            HapticManager.triggerSuccess()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onComplete()
                            }
                        })
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(GlobalTheme.roloLight.opacity(0.1)),
                        alignment: .top
                    )

                }
            }
            .navigationBarHidden(true)
            .background(GlobalTheme.brandPrimary)
        }
        .sheet(isPresented: $showingProfile) {
            // Profile view sheet
            Text("Profile View")
        }
        .sheet(isPresented: $showingSnooze) {
            // Snooze view sheet
            Text("Snooze Options")
        }
        .sheet(isPresented: $showingEdit) {
            // Edit template sheet
            Text("Edit Template")
        }
    }
}

import UIKit

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Preview Provider
struct ExpandedCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Example preview with a text card
        ExpandedCardView(card: EmailCard(
            id: UUID(),
            title: "James H.",
            date: Date(),
            sender: "Meir D.",
            subject: "Checking In",
            contentBody: "Hi James,\n\nHope you're doing well! Just checking in as it's been about 6 months since we last properly connected. How have things been?\n\nBest regards,\n[Your Name]",
            taskDescription: "Follow up: 6 months check-in",
            image: "Placeholder member profile 1",
            priority: false,
            isCompleted: false
        ), onComplete: {}, onDelete: {}, onRemove: {}, onSkip: {})
    }
}

// MARK: - Haptic Manager
struct HapticManager {
    static func triggerSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
} 
