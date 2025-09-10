import SwiftUI

// MARK: - Pill Button Style
struct PillButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(foregroundColor)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(backgroundColor)
            .cornerRadius(100)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Big Button Style
struct BigButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let strokeColor: Color?
    
    init(
        backgroundColor: Color = GlobalTheme.highlightGreen,
        foregroundColor: Color = GlobalTheme.brandPrimary,
        strokeColor: Color? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.strokeColor = strokeColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(backgroundColor)
            .cornerRadius(100)
            .overlay(
                Group {
                    if let strokeColor = strokeColor {
                        RoundedRectangle(cornerRadius: 100)
                            .stroke(strokeColor, lineWidth: 1)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Input Field Style
struct RoloTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(GlobalTheme.inputGrey)
            .cornerRadius(12)
    }
}

// MARK: - Reusable Components
struct RoloPillButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let backgroundColor: Color
    let foregroundColor: Color
    let isFill: Bool
    
    init(
        title: String,
        systemImage: String? = nil,
        backgroundColor: Color = GlobalTheme.brandPrimary,
        foregroundColor: Color = GlobalTheme.highlightGreen,
        isFill: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isFill = isFill
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                if isFill {
                    Spacer()
                }
            }
            .frame(maxWidth: isFill ? .infinity : nil)
        }
        .buttonStyle(PillButtonStyle(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ))
    }
}

struct RoloBigButton: View {
    let action: () -> Void
    let title: String
    let backgroundColor: Color
    let foregroundColor: Color
    let strokeColor: Color?
    
    init(
        title: String,
        backgroundColor: Color = GlobalTheme.highlightGreen,
        foregroundColor: Color = GlobalTheme.brandPrimary,
        strokeColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.strokeColor = strokeColor
        self.action = action
    }
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(BigButtonStyle(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                strokeColor: strokeColor
            ))
    }
}

struct RoloTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoloTextFieldStyle())
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GlobalTheme.brandPrimary, lineWidth: 2)
            )
    }
}

// MARK: - Agena messages
// Add array of empty agenda messages
let emptyAgendaMessages = [
    "Your agenda is as clean as a whistle.",
    "Nothing scheduled yet. Time to plan?",
    "Fresh start! Your agenda is empty.",
    "Clear skies ahead—no tasks in sight.",
    "Your agenda's ready for new plans.",
    "Empty agenda, endless possibilities.",
    "Start fresh—your agenda awaits.",
    "Clean slate! What's first on your list?",
    "Your day is wide open.",
    "Ready when you are—agenda's clear."
]

// Add array of completion messages
let completionMessages = [
    "Nothing left on your plate—\nunless it's kugel.",
    "All done! Time to\nschmooze or snooze.",
    "All done.\nNothing left to do!",
    "You crushed it.\nThat's everything!",
    "Mission complete.\nTake a breather.",
    "No tasks, no stress.\nEnjoy it.",
    "Everything's checked off.\nBoom.",
    "That's a wrap.\nYou did it.",
    "Zero tasks.\nOne happy you.",
    "You're all caught up.\nFor now.",
    "Look at you, totally\non top of it."
]

// MARK: - Banner
// Add new types to track undoable actions
struct UndoableAction: Identifiable {
    let id = UUID()
    let agendaTasks: [AgendaTask]
    let actionType: String
    let timestamp: Date
    var countdown: Int
}

struct UndoBanner: View {
    let count: Int
    let action: String
    let onUndo: () -> Void
    let onFinalize: () -> Void
    let countdown: Int
    @State private var offset: CGFloat = 300
    @State private var dragOffset: CGFloat = 0

    var actionText: String {
        switch action {
        case "delete": return "\(count) \(count == 1 ? "card" : "cards") deleted"
        case "complete": return "\(count) \(count == 1 ? "card" : "cards") completed"
        case "skip": return "\(count) \(count == 1 ? "card" : "cards") skipped"
        default: return "\(count) \(count == 1 ? "card" : "cards") modified"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(actionText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(GlobalTheme.brandPrimary)

            Spacer()

            Button(action: onUndo) {
                HStack(spacing: 4) {
                    Text("Undo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(GlobalTheme.brandPrimary)
                        .underline()
                }
            }
        }
        .padding(20)
        .background(GlobalTheme.roloLight.opacity(0.2))
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
        .offset(x: offset + dragOffset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Allow swiping left or right
                    if abs(gesture.translation.width) > abs(gesture.translation.height) {
                        dragOffset = gesture.translation.width
                    }
                }
                .onEnded { gesture in
                    // Dismiss if swiped more than 50 points horizontally
                    if abs(gesture.translation.width) > 50 {
                        onFinalize()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = gesture.translation.width > 0 ? 400 : -400
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = 0
            }
        }
    }
}

struct DeleteBanner: View {
    let count: Int
    let onUndo: () -> Void
    @State private var countdown: Int = 5
    @State private var timer: Timer? = nil
    @State private var offset: CGFloat = 300
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        // Banner content
        HStack(spacing: 12) {
            Text("\(count) \(count == 1 ? "card" : "cards") deleted")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(GlobalTheme.brandPrimary)
            
            Spacer()
            
            Button(action: {
                timer?.invalidate()
                onUndo()
            }) {
                HStack(spacing: 4) {
                    Text("Undo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(GlobalTheme.brandPrimary)
                        .underline()
                }
            }
        }
        .padding(20)
        .background(GlobalTheme.roloLight.opacity(0.2))
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .offset(x: offset + dragOffset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Allow swiping left or right
                    if abs(gesture.translation.width) > abs(gesture.translation.height) {
                        dragOffset = gesture.translation.width
                    }
                }
                .onEnded { gesture in
                    // Dismiss if swiped more than 50 points horizontally
                    if abs(gesture.translation.width) > 50 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = gesture.translation.width > 0 ? 400 : -400
                        }
                        timer?.invalidate()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = 0
            }
            startTimer()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 300
                }
            }
        }
    }
}


// MARK: Selection header

struct SelectionHeader: View {
    let selectedCount: Int
    let onBack: () -> Void
    let onSelectAll: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void
    let onMore: () -> Void
    let isAllSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Top row with actions
            HStack(spacing: 16) {
                // Back button and count
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                    
                    Text("\(selectedCount)")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(GlobalTheme.brandPrimary)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 24) {
                    Button(action: onComplete) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                    
                    Button(action: onMove) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20))
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                    
                    Button(action: onMore) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Bottom row with select all
            HStack(spacing: 8) {
                Button(action: onSelectAll) {
                    HStack(spacing: 8) {
                        Image(systemName: isAllSelected ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#5B696A"))
                        
                        Text("Select all")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#5B696A"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Spacer()
            }
        }
        .background(GlobalTheme.tertiaryGreen)
    }
}



// MARK: - Custom Search Bar
// Custom Search Bar with rounded corners and clear button
struct CustomSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search Members"
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.sRGB, red: 0.40, green: 0.40, blue: 0.38, opacity: 1))
            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.sRGB, red: 0.70, green: 0.70, blue: 0.70, opacity: 1))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(.sRGB, red: 0.94, green: 0.94, blue: 0.94, opacity: 1))
        .cornerRadius(22)
        .padding(.horizontal, 12)
        .padding(.top, 16)
    }
}


//MARK: - Color Picker
struct ColorTagPicker: View {
    @Binding var selectedTag: ColorTag

    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(ColorTag.allCases) { tag in
                ZStack {
                    Circle()
                        .fill(tag == .none ? Color.clear : tag.color)
                        .frame(width: 24, height: 24)

                    if tag == .none {
                        Image(systemName: "slash.circle")
                            .foregroundColor(GlobalTheme.roloDarkGrey)
                            .font(.system(size: 24))
                    }

                    if tag == selectedTag {
                        Circle()
                            .stroke(GlobalTheme.roloLightGrey, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                }
                .onTapGesture {
                    selectedTag = tag
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct UIComponents_Previews: PreviewProvider {
    @State static var selectedTag: ColorTag = .blue
    
    static var previews: some View {
        @Previewable @State var searchText = "Hello"
        VStack(spacing: 20) {
            
            ColorTagPicker(selectedTag: $selectedTag)
            
            CustomSearchBar(text: $searchText, placeholder: "Search Members")
            
            RoloPillButton(
                title: "Send Now",
                systemImage: "paperplane.fill",
                action: {}
            )
            
            RoloPillButton(
                title: "Skip",
                backgroundColor: GlobalTheme.tertiaryGreen,
                foregroundColor: GlobalTheme.brandPrimary,
                action: {}
            )
            
            RoloBigButton(
                title: "Mark Complete",
                action: {}
            )
            RoloBigButton(
                title: "Custom Colors",
                backgroundColor: .blue,
                foregroundColor: .white,
                strokeColor: .black,
                action: {}
            )
            
            RoloTextField(
                placeholder: "Enter text...",
                text: .constant("")
            )
        }
        .padding()
        .background(GlobalTheme.roloLight)
    }
} 
