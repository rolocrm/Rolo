import SwiftUI

// MARK: - Card Style Enum
enum AgendaCardStyle {
    case card
    case compact
}

struct AgendaCard: View {
    let agendaTask: AgendaTask
    let onPinToggle: (AgendaTask) -> Void
    let onDelete: (AgendaTask) -> Void
    let onRemove: (AgendaTask) -> Void
    let onComplete: (AgendaTask) -> Void
    let onSkip: (AgendaTask) -> Void
    let onPriorityToggle: (AgendaTask) -> Void
    let onSelect: (AgendaTask) -> Void
    @State private var showingUndo: Bool = false
    @State private var undoTimer: Timer? = nil
    @State private var showingExpandedCard: Bool = false
    @Binding var showingAnySheet: Bool
    let style: AgendaCardStyle
    
    init(
        agendaTask: AgendaTask,
        onPinToggle: @escaping (AgendaTask) -> Void,
        onDelete: @escaping (AgendaTask) -> Void,
        onRemove: @escaping (AgendaTask) -> Void,
        onComplete: @escaping (AgendaTask) -> Void,
        onSkip: @escaping (AgendaTask) -> Void,
        onPriorityToggle: @escaping (AgendaTask) -> Void,
        onSelect: @escaping (AgendaTask) -> Void,
        showingAnySheet: Binding<Bool>,
        style: AgendaCardStyle = .card
    ) {
        self.agendaTask = agendaTask
        self.onPinToggle = onPinToggle
        self.onDelete = onDelete
        self.onRemove = onRemove
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onPriorityToggle = onPriorityToggle
        self.onSelect = onSelect
        self._showingAnySheet = showingAnySheet
        self.style = style
    }
    
    var body: some View {
        if agendaTask.completed || agendaTask.isCompleting || agendaTask.isSkipped {
            CompletedOrSkippedCardView(
                agendaTask: agendaTask,
                showingExpandedCard: $showingExpandedCard,
                showingAnySheet: $showingAnySheet,
                onComplete: onComplete,
                onDelete: onDelete,
                onRemove: onRemove,
                onSkip: onSkip
            )
        } else {
            ActiveCardView(
                agendaTask: agendaTask,
                isCompact: style == .compact,
                showingExpandedCard: $showingExpandedCard,
                showingAnySheet: $showingAnySheet,
                onComplete: onComplete,
                onDelete: onDelete,
                onRemove: onRemove,
                onSkip: onSkip,
                onPinToggle: onPinToggle,
                onPriorityToggle: onPriorityToggle,
                onSelect: onSelect
            )
        }
    }
}

// MARK: - Helper View for Completed/Skipped Cards
private struct CompletedOrSkippedCardView: View {
    let agendaTask: AgendaTask
    @Binding var showingExpandedCard: Bool
    @Binding var showingAnySheet: Bool
    let onComplete: (AgendaTask) -> Void
    let onDelete: (AgendaTask) -> Void
    let onRemove: (AgendaTask) -> Void
    let onSkip: (AgendaTask) -> Void

    var body: some View {
        VStack() {
            HStack(spacing: 12) {
                Circle()
                    .fill(agendaTask.isSelected ? GlobalTheme.tertiaryGreen : Color.clear)
                    .frame(width: 48, height: 48)
                    .overlay(
                        agendaTask.profileImage
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    )
                HStack {
                    VStack(alignment: .leading) {
                        Text(agendaTask.name)
                            .foregroundColor(GlobalTheme.roloLightGrey)
                            .font(.system(size: 13, weight: .regular))
                        
                        Text(agendaTask.taskDescription)
                            .foregroundColor(GlobalTheme.brandPrimary)
                            .font(.system(size: 15, weight: .regular))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                if agendaTask.isSkipped {
                    HStack {
                        Text("Skipped")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(GlobalTheme.roloRed)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal,8)
                    .padding(.vertical,4)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(GlobalTheme.roloRed.opacity(0.15))
                    )
                } else {
                    HStack {
                        if agendaTask.isCompleting {
                            Image(systemName: "progress.indicator")
                                .symbolEffect(.rotate)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(GlobalTheme.highlightGreen)
                        }
                        if !agendaTask.isCompleting {
                            Text("Completed")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(GlobalTheme.highlightGreen)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .padding(.horizontal,8)
                    .padding(.vertical,4)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(GlobalTheme.tertiaryGreen)
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GlobalTheme.roloLight)
        )
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            let currentDate = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            print("--- AgendaCard Tapped (Completed/Skipped) ---")
            print("Card: \(agendaTask.name)")
            print("Is Completed: \(agendaTask.completed)")
            print("Is Skipped: \(agendaTask.isSkipped)")
            print("Is Completing: \(agendaTask.isCompleting)")
            print("Trigger Date: \(formatter.string(from: agendaTask.triggerDate))")
            if let actionDate = agendaTask.actionDate {
                print("Action Date: \(formatter.string(from: actionDate))")
                print("Is Overdue Logic Check (Action Date < Today): \(Calendar.current.startOfDay(for: actionDate) < Calendar.current.startOfDay(for: currentDate))")
            } else {
                print("Action Date: Not set")
            }
            if let completedDate = agendaTask.actionCompletedOn {
                print("Completed On: \(formatter.string(from: completedDate))")
                let hoursSinceCompletion = Calendar.current.dateComponents([.hour], from: completedDate, to: currentDate).hour ?? -1
                print("Hours Since Completion: \(hoursSinceCompletion)")
            } else {
                print("Completed On: Not set")
            }
            print("Current Date: \(formatter.string(from: currentDate))")
            print("---------------------------------------")
            if !agendaTask.isSelected {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingExpandedCard = true
                    showingAnySheet = true
                }
            }
        }
        .contextMenu {
            if !agendaTask.isDeleted && !agendaTask.isSelected {
                if agendaTask.isSkipped {
                    Button(action: {
                        onSkip(agendaTask)
                    }) {
                        Label("Mark as Not Skipped",
                              systemImage: "xmark.circle.fill")
                        .tint(GlobalTheme.brandPrimary)
                    }
                } else if agendaTask.completed {
                    Button(action: {
                        onComplete(agendaTask)
                    }) {
                        Label("Mark as Incomplete",
                              systemImage: "xmark.circle.fill")
                        .tint(GlobalTheme.brandPrimary)
                    }
                }
                Button(role: .destructive, action: {
                    withAnimation {
                        onDelete(agendaTask)
                    }
                }) {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { showingExpandedCard && showingAnySheet },
            set: { newValue in
                showingExpandedCard = newValue
                showingAnySheet = newValue
            }
        )) {
            expandedCardSheetContent
        }
    }
    
    // Extracted sheet content view builder
    @ViewBuilder
    private var expandedCardSheetContent: some View {
        switch agendaTask.type {
            case .text:
                ExpandedCardView(card: TextCard(
                    id: agendaTask.id,
                    title: agendaTask.name,
                    date: agendaTask.triggerDate,
                    contentBody: agendaTask.contentBody ?? "",
                    taskDescription: agendaTask.taskDescription,
                    image: agendaTask.image,
                    priority: agendaTask.priority,
                    isCompleted: agendaTask.completed
                ), onComplete: {
                    onComplete(agendaTask)
                }, onDelete: {
                    onDelete(agendaTask)
                }, onRemove: {
                    onRemove(agendaTask)
                }, onSkip: {
                    onSkip(agendaTask)
                })
            case .email:
                ExpandedCardView(card: EmailCard(
                    id: agendaTask.id,
                    title: agendaTask.name,
                    date: agendaTask.triggerDate,
                    sender: "sender@example.com",
                    subject: agendaTask.subject ?? "",
                    contentBody: agendaTask.contentBody ?? "",
                    taskDescription: agendaTask.taskDescription,
                    image: agendaTask.image,
                    priority: agendaTask.priority,
                    isCompleted: agendaTask.completed
                ), onComplete: {
                    onComplete(agendaTask)
                }, onDelete: {
                    onDelete(agendaTask)
                }, onRemove: {
                    onRemove(agendaTask)
                }, onSkip: {
                    onSkip(agendaTask)
                })
             case .reminder:
                 ExpandedCardView(card: ReminderCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     dueDate: agendaTask.triggerDate,
                     notes: agendaTask.taskDescription,
                     priority: agendaTask.priority ? .high : .medium,
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .payment:
                 ExpandedCardView(card: PaymentCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     amount: 100.00,
                     recipient: "Yorkville Jewish Centre",
                     status: .completed,
                     notes: agendaTask.taskDescription,
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .event:
                 ExpandedCardView(card: EventCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     startTime: agendaTask.triggerDate,
                     endTime: agendaTask.triggerDate.addingTimeInterval(3600),
                     location: "Location",
                     description: agendaTask.taskDescription,
                     attendees: [],
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .asset:
                 ExpandedCardView(card: AssetCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     fileType: .document,
                     fileSize: 1000000,
                     lastModified: agendaTask.triggerDate,
                     description: agendaTask.taskDescription,
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .checklist:
                 ExpandedCardView(card: ChecklistCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     items: [
                         ChecklistCard.ChecklistItem(title: "Item 1", isCompleted: false),
                         ChecklistCard.ChecklistItem(title: "Item 2", isCompleted: true)
                     ],
                     dueDate: agendaTask.triggerDate.addingTimeInterval(7 * 86400),
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
        }
    }
}

// MARK: - Helper View for Active Cards
private struct ActiveCardView: View {
    let agendaTask: AgendaTask
    let isCompact: Bool
    @Binding var showingExpandedCard: Bool
    @Binding var showingAnySheet: Bool
    let onComplete: (AgendaTask) -> Void
    let onDelete: (AgendaTask) -> Void
    let onRemove: (AgendaTask) -> Void
    let onSkip: (AgendaTask) -> Void
    let onPinToggle: (AgendaTask) -> Void
    let onPriorityToggle: (AgendaTask) -> Void
    let onSelect: (AgendaTask) -> Void

    var body: some View {
        ZStack {
            // Regular card layout (VStack)
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: isCompact ? 8 : 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onSelect(agendaTask)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(agendaTask.isSelected ? GlobalTheme.tertiaryGreen : Color.clear)
                                .frame(width: isCompact ? 36 : 48, height: isCompact ? 36 : 48)
                                .overlay(
                                    agendaTask.profileImage
                                        .frame(width: isCompact ? 36 : 48, height: isCompact ? 36 : 48)
                                        .clipShape(Circle())
                                )
                            if agendaTask.isSelected {
                                Circle()
                                    .fill(GlobalTheme.tertiaryGreen)
                                    .frame(width: isCompact ? 36 : 48, height: isCompact ? 36 : 48)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundColor(GlobalTheme.highlightGreen)
                                            .font(.system(size: isCompact ? 14 : 20, weight: .bold))
                                            .rotation3DEffect(
                                                .degrees(-180),
                                                axis: (x: 0, y: 1, z: 0))
                                    )
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .rotation3DEffect(
                        .degrees(agendaTask.isSelected ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )

                    VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
                        HStack {
                            Text(agendaTask.name)
                                .font(.system(size: isCompact ? 13 : 16, weight: .regular))
                                .foregroundColor(GlobalTheme.roloLight)
                            Spacer()

                            let isOverdue = agendaTask.actionDate != nil && 
                                            Calendar.current.startOfDay(for: agendaTask.actionDate!) < Calendar.current.startOfDay(for: Date()) && 
                                            !agendaTask.completed && 
                                            !agendaTask.isSkipped

                            let overdueColor = Color(hex: "#007AFF")

                            if isOverdue {
                                HStack(spacing: 6) {
                                    if agendaTask.isCompleting {
                                        Image(systemName: "progress.indicator")
                                            .symbolEffect(.rotate)
                                            .font(.system(size: isCompact ? 11 : 13, weight: .regular))
                                            .foregroundColor(GlobalTheme.highlightGreen)
                                            .padding(.trailing, 4)
                                        Text("Completing")
                                            .font(.system(size: isCompact ? 11 : 13, weight: .medium))
                                            .foregroundColor(GlobalTheme.highlightGreen)
                                    } else {
                                        Text("Overdue")
                                            .font(.system(size: isCompact ? 11 : 13, weight: .medium))
                                            .foregroundColor(overdueColor)
                                    }
                                }
                                .padding(.vertical, isCompact ? 3 : 6)
                                .padding(.horizontal, isCompact ? 6 : 10)
                                .background(
                                    agendaTask.isCompleting ? 
                                        GlobalTheme.tertiaryGreen :
                                        overdueColor.opacity(0.15)
                                )
                                .cornerRadius(40)
                            } else if agendaTask.priority {
                                HStack(spacing: 6) {
                                    Text("Priority")
                                        .font(.system(size: isCompact ? 11 : 13, weight: .medium))
                                        .foregroundColor(GlobalTheme.roloRed)
                                }
                                .padding(.vertical, isCompact ? 3 : 6)
                                .padding(.horizontal, isCompact ? 6 : 10)
                                .background(GlobalTheme.roloRed.opacity(0.15))
                                .cornerRadius(40)
                            }
                            if agendaTask.isPinned {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(Color.white.opacity(0.3))
                            }
                        }
                    }
                }
                .padding(isCompact ? 12 : 20)

                Spacer()

                HStack(alignment: .bottom, spacing: 8) {
                    Text(agendaTask.taskDescription)
                        .font(.system(size: isCompact ? 15 : 22))
                        .foregroundColor(GlobalTheme.highlightGreen)
                        .lineLimit(isCompact ? 1 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(isCompact ? 12 : 20)
            }
            .opacity(isCompact ? 0 : 1)
            .animation(.easeInOut(duration: 0.1), value: isCompact)

            // Compact layout (HStack)
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onSelect(agendaTask)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(agendaTask.isSelected ? GlobalTheme.tertiaryGreen : Color.clear)
                            .frame(width: 48)
                            .overlay(
                                agendaTask.profileImage
                                    .frame(width: 48)
                                    .clipShape(Circle())
                            )
                        if agendaTask.isSelected {
                            Circle()
                                .fill(GlobalTheme.tertiaryGreen)
                                .frame(width: 48)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .foregroundColor(GlobalTheme.highlightGreen)
                                        .font(.system(size: 20, weight: .bold))
                                        .rotation3DEffect(
                                            .degrees(-180),
                                            axis: (x: 0, y: 1, z: 0))
                                )
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .rotation3DEffect(
                    .degrees(agendaTask.isSelected ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(agendaTask.name)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(GlobalTheme.coloredGrey)
                        .lineLimit(1)
                    Text(agendaTask.taskDescription)
                        .font(.system(size: 18))
                        .foregroundColor(GlobalTheme.highlightGreen)
                        .lineLimit(2)
                }
                Spacer()
                if agendaTask.isSkipped {
                    Image(systemName: "arrow.right")
                        .foregroundColor(GlobalTheme.roloRed)
                        .help("Skipped")
                } else if agendaTask.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(GlobalTheme.highlightGreen)
                        .help("Completed")
                } else if agendaTask.isCompleting {
                    Image(systemName: "progress.indicator")
                        .symbolEffect(.rotate)
                        .foregroundColor(GlobalTheme.highlightGreen)
                        .help("Completing")
                } else if agendaTask.actionDate != nil && Calendar.current.startOfDay(for: agendaTask.actionDate!) < Calendar.current.startOfDay(for: Date()) && !agendaTask.completed && !agendaTask.isSkipped {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "#007AFF"))
                        .help("Overdue")
                } else if agendaTask.priority {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(GlobalTheme.roloRed)
                        .help("Priority")
                }
                if agendaTask.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(Color.white.opacity(0.3))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .opacity(isCompact ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isCompact)
        }
        .frame(height: isCompact ? 82 : 198)
        .clipped()
        .background {
            RoundedRectangle(cornerRadius: isCompact ? 18 : 26)
                .fill(
                    agendaTask.isDeleted ? GlobalTheme.roloLight :
                        agendaTask.isSelected ? GlobalTheme.secondaryGreen :
                    GlobalTheme.brandPrimary
                )
                .animation(.easeInOut(duration: 0.1), value: agendaTask.isSelected)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.15), value: isCompact)
        .contentShape(RoundedRectangle(cornerRadius: isCompact ? 14 : 26))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: isCompact ? 14 : 26))
        .onTapGesture {
            let currentDate = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            print("--- AgendaCard Tapped (Active) ---")
            print("Card: \(agendaTask.name)")
            print("Is Completed: \(agendaTask.completed)")
            print("Is Skipped: \(agendaTask.isSkipped)")
            print("Is Completing: \(agendaTask.isCompleting)")
            print("Trigger Date: \(formatter.string(from: agendaTask.triggerDate))")
            if let actionDate = agendaTask.actionDate {
                print("Action Date: \(formatter.string(from: actionDate))")
                print("Is Overdue Logic Check (Action Date < Today): \(Calendar.current.startOfDay(for: actionDate) < Calendar.current.startOfDay(for: currentDate))")
            } else {
                print("Action Date: Not set")
            }
            if let completedDate = agendaTask.actionCompletedOn {
                print("Completed On: \(formatter.string(from: completedDate))")
                let hoursSinceCompletion = Calendar.current.dateComponents([.hour], from: completedDate, to: currentDate).hour ?? -1
                print("Hours Since Completion: \(hoursSinceCompletion)")
            } else {
                print("Completed On: Not set")
            }
            print("Current Date: \(formatter.string(from: currentDate))")
            print("---------------------------------------")
            if !agendaTask.isSelected {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingExpandedCard = true
                    showingAnySheet = true
                }
            }
        }
        .contextMenu {
            if !agendaTask.isDeleted && !agendaTask.isSelected {
                Button(action: {
                    onComplete(agendaTask)
                }) {
                    Label("Mark as Complete",
                          systemImage: "checkmark.circle.fill")
                    .tint(GlobalTheme.brandPrimary)
                }
                Button(action: {
                    onSkip(agendaTask)
                }) {
                    Label("Skip",
                          systemImage: "arrow.right")
                    .tint(GlobalTheme.brandPrimary)
                }
                Button(action: {
                    onPinToggle(agendaTask)
                }) {
                    Label(agendaTask.isPinned ? "Remove Pin" : "Add Pin",
                          systemImage: agendaTask.isPinned ? "pin.slash.fill" : "pin.fill")
                    .tint(GlobalTheme.brandPrimary)
                }
                Button(action: {
                    onPriorityToggle(agendaTask)
                }) {
                    Label(agendaTask.priority ? "Remove Priority" : "Add Priority",
                          systemImage: agendaTask.priority ? "exclamationmark.circle.fill" : "exclamationmark.circle")
                    .tint(GlobalTheme.brandPrimary)
                }
                Button(role: .destructive, action: { // Use role for destructive actions
                    onDelete(agendaTask) // Assuming onDelete handles animation
                }) {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { showingExpandedCard && showingAnySheet },
            set: { newValue in
                showingExpandedCard = newValue
                showingAnySheet = newValue
            }
        )) {
            expandedCardSheetContent
        }
    }
    
    // Extracted sheet content view builder (can be shared or duplicated)
    @ViewBuilder
    private var expandedCardSheetContent: some View {
        switch agendaTask.type {
            case .text:
                ExpandedCardView(card: TextCard(
                    id: agendaTask.id,
                    title: agendaTask.name,
                    date: agendaTask.triggerDate,
                    contentBody: agendaTask.contentBody ?? "",
                    taskDescription: agendaTask.taskDescription,
                    image: agendaTask.image,
                    priority: agendaTask.priority,
                    isCompleted: agendaTask.completed
                ), onComplete: {
                    onComplete(agendaTask)
                }, onDelete: {
                    onDelete(agendaTask)
                }, onRemove: {
                    onRemove(agendaTask)
                }, onSkip: {
                    onSkip(agendaTask)
                })
            case .email:
                ExpandedCardView(card: EmailCard(
                    id: agendaTask.id,
                    title: agendaTask.name,
                    date: agendaTask.triggerDate,
                    sender: "sender@example.com",
                    subject: agendaTask.subject ?? "",
                    contentBody: agendaTask.contentBody ?? "",
                    taskDescription: agendaTask.taskDescription,
                    image: agendaTask.image,
                    priority: agendaTask.priority,
                    isCompleted: agendaTask.completed
                ), onComplete: {
                    onComplete(agendaTask)
                }, onDelete: {
                    onDelete(agendaTask)
                }, onRemove: {
                    onRemove(agendaTask)
                }, onSkip: {
                    onSkip(agendaTask)
                })
             case .reminder:
                 ExpandedCardView(card: ReminderCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     dueDate: agendaTask.triggerDate,
                     notes: agendaTask.taskDescription,
                     priority: agendaTask.priority ? .high : .medium,
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .payment:
                 ExpandedCardView(card: PaymentCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     amount: 100.00,
                     recipient: "Yorkville Jewish Centre",
                     status: .completed,
                     notes: agendaTask.taskDescription,
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .event:
                 ExpandedCardView(card: EventCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     startTime: agendaTask.triggerDate,
                     endTime: agendaTask.triggerDate.addingTimeInterval(3600),
                     location: "Location",
                     description: agendaTask.taskDescription,
                     attendees: [],
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .asset:
                 ExpandedCardView(card: AssetCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     fileType: .document,
                     fileSize: 1000000,
                     lastModified: agendaTask.triggerDate,
                     description: agendaTask.taskDescription,
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
             case .checklist:
                 ExpandedCardView(card: ChecklistCard(
                     id: agendaTask.id,
                     title: agendaTask.name,
                     date: agendaTask.triggerDate,
                     items: [
                         ChecklistCard.ChecklistItem(title: "Item 1", isCompleted: false),
                         ChecklistCard.ChecklistItem(title: "Item 2", isCompleted: true)
                     ],
                     dueDate: agendaTask.triggerDate.addingTimeInterval(7 * 86400),
                     image: agendaTask.image,
                     isCompleted: agendaTask.completed
                 ), onComplete: {
                     onComplete(agendaTask)
                 }, onDelete: {
                     onDelete(agendaTask)
                 }, onRemove: {
                     onRemove(agendaTask)
                 }, onSkip: {
                     onSkip(agendaTask)
                 })
        }
    }
}

#if DEBUG
struct AgendaCard_Previews: PreviewProvider {
    static var previews: some View {
        let regularMember = AgendaTask(
            name: "Robyn L.",
            taskDescription: "Just a regular task for today, and another for the next day.",
            contentBody: "This is the body for the regular text task.",
            image: "Placeholder member profile 5",
            priority: true,
            type: .text,
            triggerDate: Date() // Today
        )
        Group {
            AgendaCard(
                agendaTask: regularMember,
                onPinToggle: { _ in print("Pin toggled") },
                onDelete: { _ in print("Delete triggered") },
                onRemove: { _ in print("Remove triggered") },
                onComplete: { _ in print("Complete triggered") },
                onSkip: { _ in print("Skip triggered") },
                onPriorityToggle: { _ in print("Priority toggled") },
                onSelect: { _ in print("Select toggled") },
                showingAnySheet: .constant(false),
                style: .card
            )
            .frame(width: 392)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Card Style")
            AgendaCard(
                agendaTask: regularMember,
                onPinToggle: { _ in print("Pin toggled") },
                onDelete: { _ in print("Delete triggered") },
                onRemove: { _ in print("Remove triggered") },
                onComplete: { _ in print("Complete triggered") },
                onSkip: { _ in print("Skip triggered") },
                onPriorityToggle: { _ in print("Priority toggled") },
                onSelect: { _ in print("Select toggled") },
                showingAnySheet: .constant(false),
                style: .compact
            )
            .frame(width: 392)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Compact Style")
        }
    }
}
#endif

