//
//  DashboardView.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 4/30/25.
//

import SwiftUI


enum SortOption: String, CaseIterable {
    case date = "Date"
    case kind = "Kind"
    case nameAsc = "Name (A → Z)"
    case nameDesc = "Name (Z → A)"
}


enum TimeRange: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    @Binding var isVisible: Bool
    
    var body: some View {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedRange = range
                            isVisible = false
                        }
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 16))
                            .foregroundColor(range == selectedRange ? GlobalTheme.highlightGreen : GlobalTheme.roloDarkGrey)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 6)
                            .background(range == selectedRange ? GlobalTheme.tertiaryGreen : GlobalTheme.inputGrey)
                            .cornerRadius(60)
                    }
                }
                Spacer()
            }
            .padding(.top, -12)
            .padding(.bottom)
    }
}

struct DashboardView<Content: View>: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var authService: AuthService
    @State private var showingDeleteBanner: Bool = false
    @State private var showingCompleteBanner: Bool = false
    @State private var showingSortOptions: Bool = false
    @State private var showingNewCard: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingAnySheet: Bool = false
    @State private var showingTimeRangeSelector: Bool = false
    @State private var selectedTimeRange: TimeRange = .today
    @State private var searchText: String = ""
    @State private var isSelectionModeEnabled: Bool = false
    @State private var currentSortOption: SortOption = .date
    @State private var selectedAgendaTasks: Set<UUID> = []
    @State private var agendaTasksToDelete: [AgendaTask] = []
    @State private var agendaTasksToComplete: [AgendaTask] = []
    @State private var agendaTasksToSkip: [AgendaTask] = []
    @State private var isAgendaExpanded: Bool = true
    @State private var isEmailsExpanded: Bool = false
    @State private var isEventsExpanded: Bool = false
    @State private var isCampaignsExpanded: Bool = false
    @State private var isAutomationsExpanded: Bool = false
    @State private var selectedAction: String? = nil
    @State private var priorityFirst: Bool = true
    @State private var showingUndoBanner: Bool = false
    @State private var undoAgendaTasks: [AgendaTask] = []
    @State private var undoableActions: [UndoableAction] = []
    @State private var currentCompletionMessage: String = ""
    @State private var currentEmptyMessage: String = ""
    @State private var incompleteFirst: Bool = false
    @State private var agendaCardStyle: AgendaCardStyle = .card
    @State private var isPresentingAddMember = false
    @State private var showingCustomizeSheet = false
    @State private var homeSections: [HomeSection] = DashboardView.loadHomeSections()
    @State private var customizeSheetHeight: CGFloat = 360 // default fallback
    @State private var showingEditCommunity = false
    @State private var showingPaywall = false
    @State private var showingPaywallForLimit = false
    
    // Profile menu states
    @State private var showProfileMenu = false
    @State private var showEditProfile = false
    @State private var editedFirstName = ""
    @State private var editedLastName = ""
    @State private var editedPhoneNumber = ""
    @State private var showLogoutAlert = false
    
    // Notification state
    @State private var showingNotifications = false
    

    
    var axis: Axis.Set
    var showsIndicators: Bool
    @Binding var tabState: Visibility
    var content: Content
    init (axis: Axis.Set = .horizontal, showsIndicators: Bool, tabState: Binding<Visibility>, authService: AuthService, @ViewBuilder content: @escaping () -> Content) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self._tabState = tabState
        self.authService = authService
        self.content = content()
    }

    var filteredAgendaTasks: [AgendaTask] {
        let result = viewModel.agendaTasks
        
        // Apply existing filtering
        
        return result
    }
    
    func handlePinToggle(_ agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = viewModel.agendaTasks[index]
            updatedAgendaTask.isPinned.toggle()
            viewModel.agendaTasks[index] = updatedAgendaTask
        }
    }
    
    func showDeleteBanner() {
        undoAgendaTasks = agendaTasksToDelete
        withAnimation(.easeInOut) {
            showingDeleteBanner = false
            showUndoBanner(type: "delete")
        }
    }
    
    func handleDelete(_ agendaTask: AgendaTask) {
        agendaTasksToDelete = [agendaTask]
        viewModel.delete(agendaTask: agendaTask)
        showDeleteBanner()
        clearSelection()
    }
    
    func handleBulkDelete() {
        let selectedAgendaTasksList = viewModel.agendaTasks.filter { $0.isSelected }
        agendaTasksToDelete = selectedAgendaTasksList
        for agendaTask in selectedAgendaTasksList {
            viewModel.delete(agendaTask: agendaTask)
        }
        showDeleteBanner()
        isSelectionModeEnabled = false
    }
    
    func handleComplete(_ agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = viewModel.agendaTasks[index]

            if updatedAgendaTask.completed || updatedAgendaTask.isCompleting {
                // If already complete or completing, mark as incomplete directly
                updatedAgendaTask.completed = false
                updatedAgendaTask.isCompleting = false
                updatedAgendaTask.actionCompletedOn = nil
                viewModel.agendaTasks[index] = updatedAgendaTask
            } else {
                // If not complete, proceed with the original completion logic + undo banner
                undoAgendaTasks = [agendaTask]
                
                updatedAgendaTask.isCompleting = true
                updatedAgendaTask.actionCompletedOn = Date() // Set completion timestamp immediately
                viewModel.agendaTasks[index] = updatedAgendaTask
                
                withAnimation(.easeInOut) {
                    showUndoBanner(type: "complete")
                }
            }
        } else {
            print("Error: AgendaTask not found in handleComplete")
        }
        clearSelection()
    }
    
    func handleSkip(_ agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = viewModel.agendaTasks[index]

            if updatedAgendaTask.isSkipped {
                // If already skipped, mark as not skipped directly
                updatedAgendaTask.isSkipped = false
                updatedAgendaTask.actionCompletedOn = nil // Clear actionCompletedOn when un-skipping
                viewModel.agendaTasks[index] = updatedAgendaTask
            } else {
                // If not skipped, proceed with the skip logic + undo banner
                undoAgendaTasks = [agendaTask]
                updatedAgendaTask.isSkipped = true
                updatedAgendaTask.actionCompletedOn = Date() // Set actionCompletedOn when skipping
                viewModel.agendaTasks[index] = updatedAgendaTask
                withAnimation(.easeInOut) {
                    showUndoBanner(type: "skip")
                }
            }
        } else {
            print("Error: AgendaTask not found in handleSkip")
        }
        clearSelection()
    }
    
    private var sortedAgendaTasks: [AgendaTask] {
        // First filter out removed items
        let activeAgendaTasks = filteredAgendaTasks.filter { !$0.shouldRemove }
        
        // Determine the date range based on the selected time range
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let endDate: Date
        
        switch selectedTimeRange {
        case .today:
            endDate = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        case .week:
            endDate = calendar.date(byAdding: .day, value: 7, to: startOfToday) ?? startOfToday
        case .month:
            endDate = calendar.date(byAdding: .day, value: 30, to: startOfToday) ?? startOfToday
        }
        
        // Filter for potentially relevant agendaTasks
        let dueTasks = activeAgendaTasks.filter { agendaTask in
            let isWithinRange = agendaTask.triggerDate >= startOfToday && agendaTask.triggerDate < endDate
            let hasPastActionDate = agendaTask.actionDate != nil &&
                                  Calendar.current.startOfDay(for: agendaTask.actionDate!) < startOfToday
            
            return (isWithinRange || hasPastActionDate) && (agendaTask.hidden != true)
        }
        
        // Apply visibility filter
        let cutoff = Date().addingTimeInterval(-24.5 * 3600)
        let visibleTasks = dueTasks.filter { agendaTask in
            if !showingCompleteBanner {
                return !agendaTask.completed && !agendaTask.isCompleting && !agendaTask.isSkipped
            }
            // When showing completed, show completed, isCompleting, and isSkipped
            if agendaTask.completed || agendaTask.isCompleting || agendaTask.isSkipped {
                // If actionCompletedOn is set, check cutoff; otherwise, show
                if let actionCompletedOn = agendaTask.actionCompletedOn {
                    return actionCompletedOn >= cutoff
                } else {
                    return true
                }
            }
            return !agendaTask.completed && !agendaTask.isSkipped && !agendaTask.isCompleting
        }

        // Function to apply sorting to a list
        func sortAndGroup(agendaTasks: [AgendaTask]) -> [AgendaTask] {
            // First separate completed and incomplete tasks
            let completedTasks = agendaTasks.filter { $0.completed || $0.isSkipped }
            let incompleteTasks = agendaTasks.filter { !$0.completed && !$0.isSkipped }
            
            // For incomplete tasks, separate overdue from regular
            let startOfToday = Calendar.current.startOfDay(for: Date())
            
            // Get overdue tasks from incomplete tasks
            let overdueTasks = incompleteTasks.filter { agendaTask in
                agendaTask.actionDate != nil &&
                Calendar.current.startOfDay(for: agendaTask.actionDate!) < startOfToday &&
                !agendaTask.isSkipped
            }
            
            // Get non-overdue tasks from incomplete tasks
            let nonOverdueTasks = incompleteTasks.filter { agendaTask in
                !(agendaTask.actionDate != nil &&
                Calendar.current.startOfDay(for: agendaTask.actionDate!) < startOfToday &&
                !agendaTask.isSkipped)
            }
            
            // Sort overdue tasks by their action date
            let sortedOverdueTasks = overdueTasks.sorted { m1, m2 in
                guard let date1 = m1.actionDate, let date2 = m2.actionDate else { return false }
                return date1 < date2
            }
            
            // Handle the tasks based on showingCompleteBanner
            if showingCompleteBanner {
                // Sort completed tasks by priority and pinning
                let sortedCompleted = sortByPriority(agendaTasks: completedTasks)
                
                // Sort non-overdue tasks by priority and pinning
                let sortedNonOverdue = sortByPriority(agendaTasks: nonOverdueTasks)
                
                // If incomplete first is enabled, put completed tasks at the bottom
                if incompleteFirst {
                    return sortedOverdueTasks + sortedNonOverdue + sortedCompleted
                } else {
                    // Show completed tasks first, then overdue, then regular tasks
                    return sortedCompleted + sortedOverdueTasks + sortedNonOverdue
                }
            } else {
                // When not showing completed, just show overdue then regular tasks
                let sortedNonOverdue = sortByPriority(agendaTasks: nonOverdueTasks)
                return sortedOverdueTasks + sortedNonOverdue
            }
        }
        
        // Helper function to sort by priority
        func sortByPriority(agendaTasks: [AgendaTask]) -> [AgendaTask] {
            let startOfToday = Calendar.current.startOfDay(for: Date())
            
            // First separate overdue tasks
            let overdueTasks = agendaTasks.filter { agendaTask in
                agendaTask.actionDate != nil &&
                Calendar.current.startOfDay(for: agendaTask.actionDate!) < startOfToday &&
                !agendaTask.completed && !agendaTask.isSkipped && !agendaTask.isCompleting
            }
            let nonOverdueTasks = agendaTasks.filter { agendaTask in
                !(agendaTask.actionDate != nil &&
                Calendar.current.startOfDay(for: agendaTask.actionDate!) < startOfToday &&
                !agendaTask.completed && !agendaTask.isSkipped && !agendaTask.isCompleting)
            }
            
            // Sort overdue tasks by their action date
            let sortedOverdueTasks = overdueTasks.sorted { m1, m2 in
                guard let date1 = m1.actionDate, let date2 = m2.actionDate else { return false }
                return date1 < date2
            }
            
            // For non-overdue tasks, apply the regular pinning/priority sorting
            let pinnedAndPriority = nonOverdueTasks.filter { $0.isPinned && $0.priority }
            let pinnedOnly = nonOverdueTasks.filter { $0.isPinned && !$0.priority }
            let priorityOnly = nonOverdueTasks.filter { !$0.isPinned && $0.priority }
            let regular = nonOverdueTasks.filter { !$0.isPinned && !$0.priority }
            
            let sortedPinnedAndPriority = sortByCurrentOption(agendaTasks: pinnedAndPriority)
            let sortedPinnedOnly = sortByCurrentOption(agendaTasks: pinnedOnly)
            let sortedPriorityOnly = sortByCurrentOption(agendaTasks: priorityOnly)
            let sortedRegular = sortByCurrentOption(agendaTasks: regular)

            if priorityFirst {
                return sortedOverdueTasks + sortedPinnedAndPriority + sortedPinnedOnly + sortedPriorityOnly + sortedRegular
            } else {
                return sortedOverdueTasks + sortedPinnedAndPriority + sortedPinnedOnly + sortByCurrentOption(agendaTasks: priorityOnly + regular)
            }
        }

        return sortAndGroup(agendaTasks: visibleTasks)
    }
    
    private func sortByCurrentOption(agendaTasks: [AgendaTask]) -> [AgendaTask] {
        // First separate overdue tasks
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // Separate overdue and regular tasks
        let overdueTasks = agendaTasks.filter { agendaTask in
            agendaTask.actionDate != nil &&
            Calendar.current.startOfDay(for: agendaTask.actionDate!) < startOfToday &&
            !agendaTask.completed && !agendaTask.isSkipped && !agendaTask.isCompleting
        }
        
        let regularTasks = agendaTasks.filter { agendaTask in
            !(agendaTask.actionDate != nil &&
            Calendar.current.startOfDay(for: agendaTask.actionDate!) < startOfToday &&
            !agendaTask.completed && !agendaTask.isSkipped && !agendaTask.isCompleting)
        }
        
        // Sort overdue tasks by their action date (oldest first)
        let sortedOverdueTasks = overdueTasks.sorted { m1, m2 in
            guard let date1 = m1.actionDate, let date2 = m2.actionDate else { return false }
            return date1 < date2
        }
        
        // Sort remaining tasks according to the current sort option
        let sortedRegularTasks = regularTasks.sorted { m1, m2 in
            switch currentSortOption {
            case .date:
                // For completed tasks, sort by completion date first
                if m1.completed && m2.completed {
                    guard let date1 = m1.actionCompletedOn, let date2 = m2.actionCompletedOn else {
                        return m1.triggerDate < m2.triggerDate
                    }
                    return date1 > date2
                }
                return m1.triggerDate < m2.triggerDate
            case .kind:
                return String(describing: m1.type) < String(describing: m2.type)
            case .nameAsc:
                return m1.name < m2.name
            case .nameDesc:
                return m1.name > m2.name
            }
        }
        
        // Always return overdue tasks first, followed by regularly sorted tasks
        return sortedOverdueTasks + sortedRegularTasks
    }
    
    private func togglePin(for agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.type = agendaTask.type == .reminder ? .event : .reminder
            viewModel.agendaTasks[index] = updatedAgendaTask
        }
    }
    
    private func deleteAgendaTask(_ agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.isDeleted.toggle()
            viewModel.agendaTasks[index] = updatedAgendaTask
        }
    }
    
    private func removeAgendaTask(_ agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.shouldRemove = true
            viewModel.agendaTasks[index] = updatedAgendaTask
        }
    }
    
    private func toggleComplete(_ agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = agendaTask
            if !agendaTask.completed {
                updatedAgendaTask.isCompleting = true
                viewModel.agendaTasks[index] = updatedAgendaTask
                
                DispatchQueue.main.asyncAfter(deadline: .now()  + 3) {
                    if let finalIndex = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
                        var finalAgendaTask = viewModel.agendaTasks[finalIndex]
                        finalAgendaTask.isCompleting = false
                        finalAgendaTask.completed = true
                        viewModel.agendaTasks[finalIndex] = finalAgendaTask
                    }
                }
            } else {
                updatedAgendaTask.completed = false
                viewModel.agendaTasks[index] = updatedAgendaTask
            }
        }
    }
    
    private func togglePriority(for agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.priority.toggle()
            viewModel.agendaTasks[index] = updatedAgendaTask
        }
    }
    
    private func toggleSelection(for agendaTask: AgendaTask) {
        if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.isSelected.toggle()
            viewModel.agendaTasks[index] = updatedAgendaTask
        }
    }

    private var isAllSelected: Bool {
        // Check if all visible non-completed tasks are selected
        let visibleTasks = sortedAgendaTasks.filter { !$0.completed } // This already has our filtering logic
        return !visibleTasks.isEmpty && visibleTasks.allSatisfy { $0.isSelected }
    }
    
    private func clearSelection() {
        print("clearSelection called. Selected tasks before clearing:", viewModel.agendaTasks.filter { $0.isSelected }.map { $0.id })
        for (index, agendaTask) in viewModel.agendaTasks.enumerated() {
            if agendaTask.isSelected {
                print("Clearing selection for task: \(agendaTask.id)")
                var updatedAgendaTask = agendaTask
                updatedAgendaTask.isSelected = false
                viewModel.agendaTasks[index] = updatedAgendaTask
            }
        }
        print("Selected tasks after clearing:", viewModel.agendaTasks.filter { $0.isSelected }.map { $0.id })
    }
    
    private func selectAll() {
        if isAllSelected {
            clearSelection()
        } else {
            // Get the IDs of all currently visible and non-completed tasks
            let visibleTaskIds = Set(sortedAgendaTasks.filter { !$0.completed }.map { $0.id })
            
            // Only select tasks that are currently visible and not completed
            for (index, agendaTask) in viewModel.agendaTasks.enumerated() {
                if visibleTaskIds.contains(agendaTask.id) {
                    var updatedAgendaTask = agendaTask
                    updatedAgendaTask.isSelected = true
                    viewModel.agendaTasks[index] = updatedAgendaTask
                }
            }
        }
    }
    
    private func completeSelected() {
        let selectedCount = viewModel.agendaTasks.filter { $0.isSelected }.count
        if selectedCount > 0 {
            undoAgendaTasks = viewModel.agendaTasks.filter { $0.isSelected }

            // Mark tasks as completing and set timestamp temporarily
            let completionTime = Date()
            for agendaTask in viewModel.agendaTasks.filter({ $0.isSelected }) {
                if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
                    var updatedAgendaTask = agendaTask
                    updatedAgendaTask.isCompleting = true
                    updatedAgendaTask.actionCompletedOn = completionTime // Set timestamp immediately
                    viewModel.agendaTasks[index] = updatedAgendaTask
                }
            }

            // Show undo banner
            withAnimation(.easeInOut) {
                showUndoBanner(type: "complete")
            }
        }
        clearSelection()
    }
    
    private func finalizeAction(action: UndoableAction) {
        // Finalize based on action type - Apply the changes
        for agendaTask in action.agendaTasks {
            if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
                var updatedAgendaTask = agendaTask
                updatedAgendaTask.isSelected = false // Always clear selection on finalize
                switch action.actionType {
                case "delete":
                    updatedAgendaTask.shouldRemove = true
                case "complete":
                    updatedAgendaTask.isCompleting = false
                    updatedAgendaTask.completed = true
                case "skip":
                    updatedAgendaTask.isSkipped = true
                default:
                    break
                }
                viewModel.agendaTasks[index] = updatedAgendaTask
            }
        }
    }

    private func handleUndo(action: UndoableAction) {
        // Restore tasks for this specific action
        for agendaTask in action.agendaTasks {
            if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
                var updatedAgendaTask = agendaTask
                // Do NOT clear selection on undo
                switch action.actionType {
                case "delete":
                    updatedAgendaTask.shouldRemove = false
                case "complete":
                    updatedAgendaTask.isCompleting = false
                    updatedAgendaTask.completed = false
                    updatedAgendaTask.actionCompletedOn = nil
                case "skip":
                    updatedAgendaTask.isSkipped = false
                default:
                    break
                }
                viewModel.agendaTasks[index] = updatedAgendaTask
            }
        }

        // Remove this action from the stack
        if let index = undoableActions.firstIndex(where: { $0.id == action.id }) {
            undoableActions.remove(at: index)
        }

        // Hide banner if no more actions
        if undoableActions.isEmpty {
            withAnimation(.easeInOut) {
                showingUndoBanner = false
            }
        }
    }

    // Add helper computed property to determine if there are any tasks in the current time range
    private var hasTasksInTimeRange: Bool {
        let activeAgendaTasks = filteredAgendaTasks.filter { !$0.shouldRemove }
        let calendar = Calendar.current
        let today = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .today:
            startDate = calendar.startOfDay(for: today)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        }
        
        return activeAgendaTasks.contains { agendaTask in
            agendaTask.triggerDate >= startDate && agendaTask.triggerDate <= today && (agendaTask.hidden != true)
        }
    }

    private func showUndoBanner(type: String, duration: Int = 5) {
        // Create new undoable action
        let newAction = UndoableAction(
            agendaTasks: undoAgendaTasks,
            actionType: type,
            timestamp: Date(),
            countdown: duration
        )
        
        // If we already have 3 actions, remove the oldest one
        if undoableActions.count >= 3 {
            // Finalize the oldest action before removing it
            finalizeAction(action: undoableActions[0])
            undoableActions.removeFirst()
        }
        
        undoableActions.append(newAction)
        showingUndoBanner = true
        
        // Start timer for this specific action
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let index = undoableActions.firstIndex(where: { $0.id == newAction.id }) {
                if undoableActions[index].countdown > 1 {
                    undoableActions[index].countdown -= 1
                } else {
                    // Timer completed, finalize this specific action
                    withAnimation(.easeInOut) {
                        self.finalizeAction(action: undoableActions[index])
                        undoableActions.remove(at: index)
                        if undoableActions.isEmpty {
                            showingUndoBanner = false
                        }
                    }
                    timer.invalidate()
                }
            } else {
                timer.invalidate()
            }
        }
    }

    private func deleteSelected() {
        let selectedCount = viewModel.agendaTasks.filter { $0.isSelected }.count
        if selectedCount > 0 {
            undoAgendaTasks = viewModel.agendaTasks.filter { $0.isSelected }
            for agendaTask in viewModel.agendaTasks.filter({ $0.isSelected }) {
                if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
                    var updatedAgendaTask = agendaTask
                    updatedAgendaTask.shouldRemove = true
                    viewModel.agendaTasks[index] = updatedAgendaTask
                }
            }
            withAnimation(.easeInOut) {
                showUndoBanner(type: "delete")
            }
        }
        clearSelection()
    }

    private func skipSelected() {
        let selectedCount = viewModel.agendaTasks.filter { $0.isSelected }.count
        if selectedCount > 0 {
            undoAgendaTasks = viewModel.agendaTasks.filter { $0.isSelected }

            // Mark tasks as skipped
            for agendaTask in viewModel.agendaTasks.filter({ $0.isSelected }) {
                if let index = viewModel.agendaTasks.firstIndex(where: { $0.id == agendaTask.id }) {
                    var updatedAgendaTask = agendaTask
                    updatedAgendaTask.isSkipped = true
                    viewModel.agendaTasks[index] = updatedAgendaTask
                }
            }

            // Show undo banner
            withAnimation(.easeInOut) {
                showUndoBanner(type: "skip")
            }
        }
        clearSelection()
    }

    // MARK: View
    var body: some View {
        ZStack(alignment: .bottom) {
            
            ZStack {
                NavigationView {
                    ZStack(alignment: .top) {
                        // TODO: Add 'if availible' (iOS 17)
                            ScrollView(axis) {
                            VStack(alignment: .leading, spacing: 12) {
                                //Header
                                HStack {
                                    Text(viewModel.selectedCommunity?.name ?? "Yorkville Jewish Centre")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    
                                    // Upgrade button (example)
                                    Button(action: {
                                        showingPaywall = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "crown.fill")
                                                .font(.caption)
                                            Text("Upgrade")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(6)
                                    }
                                    
                                    // Notification icon with dot indicator
                                    Button(action: {
                                        showingNotifications = true
                                    }) {
                                        ZStack {
                                            Image(systemName: "bell")
                                                .font(.system(size: 20))
                                                .foregroundColor(GlobalTheme.brandPrimary)
                                                
                                            
                                            // Notification dot indicator
                                            if true { // TODO: Replace with actual notification state
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 10, height: 10)
                                                    .offset(x: 6, y: -6)
                                                Circle()
                                                    .fill(GlobalTheme.highlightGreen)
                                                    .frame(width: 6, height: 6)
                                                    .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .padding(.trailing, 12)
                                    
                                    Button(action: {
                                        showProfileMenu = true
                                    }) {
                                        if let profile = authService.currentUserProfile,
                                           let avatarUrl = profile.avatarUrl,
                                           !avatarUrl.isEmpty {
                                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Image(systemName: "person.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 48))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .confirmationDialog("Profile Options", isPresented: $showProfileMenu) {
                                        Button("Edit Profile") {
                                            if let profile = authService.currentUserProfile {
                                                editedFirstName = profile.firstName
                                                editedLastName = profile.lastName
                                                editedPhoneNumber = profile.phoneNumber ?? ""
                                            }
                                            showEditProfile = true
                                        }
                                        
                                        Button("Edit Community") {
                                            showingEditCommunity = true
                                        }
                                        
                                        Button("Log Out", role: .destructive) {
                                            showLogoutAlert = true
                                        }
                                        
                                        Button("Cancel", role: .cancel) { }
                                    }
                                }
                                .padding()
                                
                                // TODO: place the loader here instead of at the top
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        RoloPillButton(
                                            title: "Add member",
                                            systemImage: "person.badge.plus",
                                            backgroundColor: selectedAction == "addMember" ? GlobalTheme.brandPrimary : GlobalTheme.tertiaryGreen,
                                            foregroundColor: selectedAction == "addMember" ? GlobalTheme.highlightGreen : GlobalTheme.highlightGreen,
                                            action: {
                                                isPresentingAddMember = true
                                                selectedAction = "addMember"
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                    selectedAction = nil
                                                }
                                            }
                                        )
                                        .fullScreenCover(isPresented: $isPresentingAddMember) {
                                            NavigationStack {
                                                AddNewMemberView()
                                            }
                                        }
                                        
                                        RoloPillButton(
                                            title: "New reminder",
                                            systemImage: "plus",
                                            backgroundColor: selectedAction == "newReminder" ? GlobalTheme.brandPrimary : GlobalTheme.tertiaryGreen,
                                            foregroundColor: selectedAction == "newReminder" ? GlobalTheme.highlightGreen : GlobalTheme.highlightGreen,
                                            action: {
                                                selectedAction = "newReminder"
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                    selectedAction = nil
                                                }
                                            }
                                        )

                                        
                                        RoloPillButton(
                                            title: "Create event",
                                            systemImage: "calendar.badge.plus",
                                            backgroundColor: selectedAction == "createEvent" ? GlobalTheme.brandPrimary : GlobalTheme.tertiaryGreen,
                                            foregroundColor: selectedAction == "createEvent" ? GlobalTheme.highlightGreen : GlobalTheme.highlightGreen,
                                            action: {
                                                selectedAction = "createEvent"
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                    selectedAction = nil
                                                }
                                            }
                                        )
                                        
                                        RoloPillButton(
                                            title: "Request donation",
                                            systemImage: "heart.circle",
                                            backgroundColor: selectedAction == "requestDonation" ? GlobalTheme.brandPrimary : GlobalTheme.tertiaryGreen,
                                            foregroundColor: selectedAction == "requestDonation" ? GlobalTheme.highlightGreen : GlobalTheme.highlightGreen,
                                            action: {
                                                selectedAction = "requestDonation"
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                    selectedAction = nil
                                                }
                                            }
                                        )
                                        
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // MARK: Dynamic Home Sections
                                ForEach(homeSections.filter { $0.isActive }) { section in
                                    switch section.name {
                                    case "Agenda":
                                        // Agenda Feed
                                        VStack{
                                            HStack (spacing: 0) {
                                                Button(action: {
                                                    withAnimation(.spring()) {
                                                        showingTimeRangeSelector.toggle()
                                                    }
                                                }) {
                                                    HStack(spacing: 0) {
                                                        Text(selectedTimeRange.rawValue)
                                                            .font(.headline)
                                                            .foregroundColor(isAgendaExpanded ? GlobalTheme.highlightGreen : GlobalTheme.brandPrimary)
                                                            .underline(isAgendaExpanded)
                                                            .animation(.easeInOut(duration: 1), value: isAgendaExpanded)
                                                    }
                                                }
                                                Button(action: {
                                                    withAnimation(.spring()) {
                                                        isAgendaExpanded.toggle()
                                                        showingTimeRangeSelector = false
                                                    }
                                                }) {
                                                    HStack(spacing: 0) {
                                                        Text("'s agenda")
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                        Spacer()
                                                    }
                                                }
                                                HStack(spacing: 0) {
                                                    if isAgendaExpanded {
                                                        Button(action: {
                                                            withAnimation {
                                                                showingCompleteBanner.toggle()
                                                            }
                                                        }) {
                                                            Image(systemName: showingCompleteBanner ? "eye" : "eye.slash")
                                                                .foregroundColor(GlobalTheme.brandPrimary)
                                                                .font(.system(size: 16, weight: .semibold))
                                                                .contentTransition(.symbolEffect(.replace))
                                                                .padding(12)
                                                                .contentShape(Rectangle())
                                                                .frame(height: 32)
                                                        }
                                                        
                                                        Menu {
                                                            // View options section
                                                            Text("View options")
                                                                .font(.subheadline)
                                                                .foregroundColor(.secondary)
                                                            
                                                            // Priority toggle
                                                            Button(action: {
                                                                withAnimation {
                                                                    priorityFirst.toggle()
                                                                }
                                                            }) {
                                                                HStack {
                                                                    Text("Priority tasks first")
                                                                    if priorityFirst {
                                                                        Image(systemName: "checkmark")
                                                                    }
                                                                }
                                                            }
                                                            
                                                            // Incomplete first toggle
                                                            Button(action: {
                                                                withAnimation {
                                                                    incompleteFirst.toggle()
                                                                }
                                                            }) {
                                                                HStack {
                                                                    Text("Incomplete tasks first")
                                                                    if incompleteFirst {
                                                                        Image(systemName: "checkmark")
                                                                    }
                                                                }
                                                            }
                                                            
                                                            // Compact view toggle
                                                            Button(action: {
                                                                withAnimation {
                                                                    agendaCardStyle = agendaCardStyle == .card ? .compact : .card
                                                                }
                                                            }) {
                                                                HStack {
                                                                    Text("Compact view")
                                                                    if agendaCardStyle == .compact {
                                                                        Image(systemName: "checkmark")
                                                                    }
                                                                }
                                                            }
                                                            
                                                            Divider()
                                                            
                                                            // Sort options section
                                                            Text("Sort tasks by")
                                                                .font(.subheadline)
                                                                .foregroundColor(.secondary)
                                                            
                                                            // All sort options
                                                            ForEach(SortOption.allCases, id: \.self) { option in
                                                                Button(action: {
                                                                    currentSortOption = option
                                                                }) {
                                                                    HStack {
                                                                        Text(option.rawValue)
                                                                        if currentSortOption == option {
                                                                            Image(systemName: "checkmark")
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        } label: {
                                                            Image(systemName: "line.3.horizontal.decrease")
                                                                .foregroundColor(GlobalTheme.brandPrimary)
                                                                .font(.system(size: 16, weight: .semibold))
                                                                .padding(12)
                                                                .contentShape(Rectangle())
                                                        }
                                                    }
                                                    
                                                    Button(action: {
                                                        withAnimation(.spring()) {
                                                            isAgendaExpanded.toggle()
                                                            showingTimeRangeSelector = false
                                                        }
                                                    }) {
                                                        Image(systemName: "chevron.down")
                                                            .foregroundColor(GlobalTheme.brandPrimary)
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .rotationEffect(.degrees(isAgendaExpanded ? 0 : -90))
                                                            .padding(.leading, 12)
                                                            .padding(.vertical, isAgendaExpanded ? 12 : 0)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, isAgendaExpanded ? 8 : 20)
                                            
                                            if isAgendaExpanded {
                                                
                                                VStack(alignment: .leading) {
                                                    if showingTimeRangeSelector {
                                                        TimeRangeSelector(
                                                            selectedRange: $selectedTimeRange,
                                                            isVisible: $showingTimeRangeSelector
                                                        )
                                                    }
                                                }
                                                .padding(.horizontal)
                                                
                                                
                                                VStack(spacing: agendaCardStyle == .compact ? 4 : 10) {
                                                    if !hasTasksInTimeRange {
                                                        // No tasks scheduled for this time range
                                                        VStack(spacing: 10) {
                                                            Image(systemName: "plus.circle")
                                                                .font(.system(size: 20))
                                                                .foregroundColor(GlobalTheme.roloLightGrey)
                                                            
                                                            Text(currentEmptyMessage)
                                                                .font(.system(size: 15))
                                                                .foregroundColor(GlobalTheme.roloLightGrey)
                                                                .multilineTextAlignment(.center)
                                                                .padding(.horizontal)
                                                        }
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                        .padding(.vertical, 48)
                                                        .onAppear {
                                                            currentEmptyMessage = emptyAgendaMessages.randomElement() ?? "Your agenda is empty."
                                                        }
                                                    } else if sortedAgendaTasks.isEmpty {
                                                        // Had tasks but they're all completed
                                                        VStack(spacing: 10) {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .font(.system(size: 20))
                                                                .foregroundColor(GlobalTheme.highlightGreen)
                                                            
                                                            Text(currentCompletionMessage)
                                                                .font(.system(size: 15))
                                                                .foregroundColor(GlobalTheme.brandPrimary)
                                                                .multilineTextAlignment(.center)
                                                                .padding(.horizontal)
                                                        }
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                        .padding(.vertical, 48)
                                                    } else {
                                                        ForEach(sortedAgendaTasks.filter { !$0.shouldRemove }) { agendaTask in
                                                            AgendaCard(agendaTask: agendaTask,
                                                                       onPinToggle: handlePinToggle,
                                                                       onDelete: handleDelete,
                                                                       onRemove: removeAgendaTask,
                                                                       onComplete: handleComplete,
                                                                       onSkip: handleSkip,
                                                                       onPriorityToggle: togglePriority,
                                                                       onSelect: toggleSelection,
                                                                       showingAnySheet: $showingAnySheet,
                                                                       style: agendaCardStyle)
                                                            .padding(.horizontal)
                                                        }
                                                    }
                                                }
                                                .padding(.bottom)
                                                .onChange(of: sortedAgendaTasks.count) { _, newCount in
                                                    if newCount == 0 && hasTasksInTimeRange {
                                                        currentCompletionMessage = completionMessages.randomElement() ?? "All done!"
                                                    }
                                                }
                                                .onChange(of: selectedTimeRange) { _, _ in
                                                    // Update empty message when time range changes and there are no tasks
                                                    if !hasTasksInTimeRange {
                                                        currentEmptyMessage = emptyAgendaMessages.randomElement() ?? "Your agenda is empty."
                                                    }
                                                }
                                            }
                                        }
                                        .background(Color.white)
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: isEmailsExpanded ? 20 : 12)
//                                                .stroke(GlobalTheme.roloLightGrey20, lineWidth: isEmailsExpanded ? 0 : 2)
//                                        )
                                        .cornerRadius(isAgendaExpanded ? 20 : 12)
                                        .padding(.horizontal, isAgendaExpanded ? 0 : 12)
                                        .shadow(color: isAgendaExpanded ? GlobalTheme.brandPrimary.opacity(0.12) : .clear, radius: isAgendaExpanded ? 10 : 0)
                                        
                                    case "Emails":
                                        // Email Feed
                                        VStack{
                                            HStack (spacing: 0) {
                                                Button(action: {
                                                    withAnimation(.spring()) {
                                                        isEmailsExpanded.toggle()
                                                    }
                                                }) {
                                                    HStack(spacing: 0) {
                                                        Text("Emails")
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                        Spacer()
                                                    }
                                                }
                                                HStack(spacing: 16) {
                                                    Button(action: {
                                                        withAnimation(.spring()) {
                                                            isEmailsExpanded.toggle()
                                                        }
                                                    }) {
                                                        Image(systemName: "chevron.down")
                                                            .foregroundColor(GlobalTheme.brandPrimary)
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .rotationEffect(.degrees(isEmailsExpanded ? 0 : -90))
                                                    }
                                                }
                                            }
                                            .padding(20)
                                        }
                                        .background(Color.white)
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: isEmailsExpanded ? 20 : 12)
//                                                .stroke(GlobalTheme.roloLightGrey20, lineWidth: isEmailsExpanded ? 0 : 2)
//                                        )
                                        .cornerRadius(isEmailsExpanded ? 20 : 12)
                                        .padding(.horizontal, isEmailsExpanded ? 0 : 12)
                                        .shadow(color: isEmailsExpanded ? GlobalTheme.brandPrimary.opacity(0.12) : .clear, radius: isEmailsExpanded ? 10 : 0)
                                    case "Events":
                                        // Events Feed
                                        VStack{
                                            HStack (spacing: 0) {
                                                Button(action: {
                                                    withAnimation(.spring()) {
                                                        isEventsExpanded.toggle()
                                                    }
                                                }) {
                                                    HStack(spacing: 0) {
                                                        Text("Events")
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                        Spacer()
                                                    }
                                                }
                                                HStack(spacing: 16) {
                                                    Button(action: {
                                                        withAnimation(.spring()) {
                                                            isEventsExpanded.toggle()
                                                        }
                                                    }) {
                                                        Image(systemName: "chevron.down")
                                                            .foregroundColor(GlobalTheme.brandPrimary)
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .rotationEffect(.degrees(isEventsExpanded ? 0 : -90))
                                                    }
                                                }
                                            }
                                            .padding(20)
                                        }
                                        .background(Color.white)
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: isEmailsExpanded ? 20 : 12)
//                                                .stroke(GlobalTheme.roloLightGrey20, lineWidth: isEmailsExpanded ? 0 : 2)
//                                        )
                                        .cornerRadius(isEventsExpanded ? 20 : 12)
                                        .padding(.horizontal, isEventsExpanded ? 0 : 12)
                                        .shadow(color: isEventsExpanded ? GlobalTheme.brandPrimary.opacity(0.12) : .clear, radius: isEventsExpanded ? 10 : 0)
                                    case "Campaigns":
                                        // Campaigns Feed
                                        VStack{
                                            HStack (spacing: 0) {
                                                Button(action: {
                                                    withAnimation(.spring()) {
                                                        isCampaignsExpanded.toggle()
                                                    }
                                                }) {
                                                    HStack(spacing: 0) {
                                                        Text("Campaigns")
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                        Spacer()
                                                    }
                                                }
                                                HStack(spacing: 16) {
                                                    Button(action: {
                                                        withAnimation(.spring()) {
                                                            isCampaignsExpanded.toggle()
                                                        }
                                                    }) {
                                                        Image(systemName: "chevron.down")
                                                            .foregroundColor(GlobalTheme.brandPrimary)
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .rotationEffect(.degrees(isCampaignsExpanded ? 0 : -90))
                                                    }
                                                }
                                            }
                                            .padding(20)
                                        }
                                        .background(Color.white)
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: isEmailsExpanded ? 20 : 12)
//                                                .stroke(GlobalTheme.roloLightGrey20, lineWidth: isEmailsExpanded ? 0 : 2)
//                                        )
                                        .cornerRadius(isCampaignsExpanded ? 20 : 12)
                                        .padding(.horizontal, isCampaignsExpanded ? 0 : 12)
                                        .shadow(color: isCampaignsExpanded ? GlobalTheme.brandPrimary.opacity(0.12) : .clear, radius: isCampaignsExpanded ? 10 : 0)
                                    case "Automations":
                                        // Automations Feed
                                        VStack{
                                            HStack (spacing: 0) {
                                                Button(action: {
                                                    withAnimation(.spring()) {
                                                        isAutomationsExpanded.toggle()
                                                    }
                                                }) {
                                                    HStack(spacing: 0) {
                                                        Text("Automations")
                                                            .font(.headline)
                                                            .foregroundColor(.primary)
                                                        Spacer()
                                                    }
                                                }
                                                HStack(spacing: 16) {
                                                    Button(action: {
                                                        withAnimation(.spring()) {
                                                            isAutomationsExpanded.toggle()
                                                        }
                                                    }) {
                                                        Image(systemName: "chevron.down")
                                                            .foregroundColor(GlobalTheme.brandPrimary)
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .rotationEffect(.degrees(isAutomationsExpanded ? 0 : -90))
                                                    }
                                                }
                                            }
                                            .padding(20)
                                        }
                                        .background(Color.white)
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: isEmailsExpanded ? 20 : 12)
//                                                .stroke(GlobalTheme.roloLightGrey20, lineWidth: isEmailsExpanded ? 0 : 2)
//                                        )
                                        .cornerRadius(isAutomationsExpanded ? 20 : 12)
                                        .padding(.horizontal, isAutomationsExpanded ? 0 : 12)
                                        .shadow(color: isAutomationsExpanded ? GlobalTheme.brandPrimary.opacity(0.12) : .clear, radius: isAutomationsExpanded ? 10 : 0)
                                    default:
                                        EmptyView()
                                    }
                                }
                                // MARK: End Dynamic Home Sections
                                
                                HStack (alignment: .center) {
                                    Text("Customize home page")
                                        .underline()
                                        .foregroundStyle(GlobalTheme.roloLightGrey)
                                        .onTapGesture {
                                            showingCustomizeSheet = true
                                        }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .padding(.bottom, 20)
                                .sheet(isPresented: $showingCustomizeSheet) {
                                    CustomizeHomeSheet(sections: $homeSections)
                                        .presentationDetents([.height(customizeSheetHeight)])
                                }
                            }
                            
                        }
                            .background(Color.white)
                            .scrollIndicators(showsIndicators ? .visible : .hidden)
                            .refreshable {
                                await Task {
                                    viewModel.refreshData()
                                }.value
                            }
                            .background {
                                CustomPanGesture(onChange: handleTabState)
                            }
                        // TODO: Add else if user doesnt have iOS 17
                        //MARK: TODO!
                        
                        // Selection header
                        let selectedTasks = viewModel.agendaTasks.filter({ $0.isSelected })
                        if !selectedTasks.isEmpty {
                            SelectionHeader(
                                selectedCount: viewModel.agendaTasks.filter({ $0.isSelected }).count,
                                onBack: clearSelection,
                                onSelectAll: selectAll,
                                onComplete: completeSelected,
                                onDelete: deleteSelected,
                                onMove: skipSelected,
                                onMore: {},
                                isAllSelected: isAllSelected
                            )
                            .onAppear {
                                print("SelectionHeader showing for: ", selectedTasks.map { $0.id })
                            }
                        }
                    }
                }

                
            }
            
            if showingAnySheet {
                Color.clear
                    .background(GlobalTheme.highlightGreen.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: showingAnySheet)
            }
            
            // Delete banner
            if showingDeleteBanner {
                DeleteBanner(count: viewModel.agendaTasks.filter({ $0.shouldRemove }).count, onUndo: { handleUndo(action: undoableActions.first!) })
            }
            
            // Replace single undo banner with stack of undo banners
            if showingUndoBanner {
                VStack(spacing: 8) {
                    // Only show the last 3 actions
                    ForEach(Array(undoableActions.suffix(3))) { action in
                        UndoBanner(
                            count: action.agendaTasks.count,
                            action: action.actionType,
                            onUndo: { handleUndo(action: action) },
                            onFinalize: {
                                finalizeAction(action: action)
                                if let index = undoableActions.firstIndex(where: { $0.id == action.id }) {
                                    undoableActions.remove(at: index)
                                    if undoableActions.isEmpty {
                                        showingUndoBanner = false
                                    }
                                }
                            },
                            countdown: action.countdown
                        )
                    }
                }
                .padding(.bottom, 40)  // Add padding to the entire stack instead of individual banners
            }
        }
        .onChange(of: homeSections) {
            saveHomeSections()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(
                authService: authService,
                firstName: $editedFirstName,
                lastName: $editedLastName,
                phoneNumber: $editedPhoneNumber,
                isPresented: $showEditProfile
            )
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    do {
                        try await authService.signOut()
                        // Note: You'll need to handle navigation back to login screen
                        // This might require a callback or environment object
                    } catch {
                        print("❌ Logout error: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showingEditCommunity) {
            EditCommunityView(
                authService: authService,
                isPresented: $showingEditCommunity
            )
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingPaywallForLimit) {
            PaywallView(preselectedPlan: getProPlan())
        }
    }
    func handleTabState(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let velocityY = gesture.velocity(in: view).y
        
        if velocityY < 0 {
            // Swiping up
            if abs(velocityY) > 300 && tabState == .visible {
                tabState = .hidden
            }
        } else {
            // Swiping down
            if velocityY > 200 && tabState == .hidden {
                tabState = .visible
            }
        }
    }
    
    // MARK: - Paywall Helpers
    
    private func getProPlan() -> SubscriptionPlan {
        return SubscriptionPlan(
            id: UUID(),
            name: "pro",
            displayName: "Pro",
            description: "Advanced features for growing communities",
            priceMonthly: 350.00,
            priceYearly: 280.00,
            maxTeamMembers: 2,
            maxViewers: 0,
            features: [
                "max_members": 250,
                "birthday_reminders": true,
                "donation_links": true,
                "email_templates": true,
                "trial_days": 30,
                "email_limit": 100
            ],
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        )
    }
    
    // Example: Show paywall when user hits team member limit
    private func checkTeamMemberLimit() {
        // This would check your subscription service
        // For now, showing as example
        showingPaywallForLimit = true
    }
    
    // Example: Show paywall when user tries to add more members
    private func showPaywallForMemberLimit() {
        showingPaywallForLimit = true
    }
}
struct CustomPanGesture: UIViewRepresentable {
    var onChange: (UIPanGestureRecognizer) -> Void
    private let gestureID = UUID().uuidString
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let superview = uiView.superview?.superview else { return }
            if !(superview.gestureRecognizers?.contains { $0.name == gestureID } ?? false) {
                let gesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.gestureChanged))
                gesture.name = gestureID
                gesture.delegate = context.coordinator
                superview.addGestureRecognizer(gesture)
            }
        }
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChange: (UIPanGestureRecognizer) -> Void
        init(onChange: @escaping (UIPanGestureRecognizer) -> Void) {
            self.onChange = onChange
        }

        @objc func gestureChanged(_ gesture: UIPanGestureRecognizer) {
            onChange(gesture)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

// MARK: Home Section Model
struct HomeSection: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var isActive: Bool
    var icon: String

    init(id: UUID = UUID(), name: String, isActive: Bool, icon: String) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.icon = icon
    }
}

// MARK: Customize Home Sheet
struct CustomizeHomeSheet: View {
    @State private var editMode: EditMode = .active
    @Binding var sections: [HomeSection]
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 0) {
                    Text("Customize Home Page")
                        .font(.title2).bold()
                        .foregroundStyle(GlobalTheme.brandPrimary)
                        .padding(.top, 20)
                        .padding(.horizontal)
                    Text("Show, hide, or reorder sections on your home page.")
                        .font(.subheadline)
                        .foregroundColor(GlobalTheme.roloDarkGrey)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    
                    List {
                        ForEach($sections, id: \.id) { $section in
                            HStack {
                                Image(systemName: section.icon)
                                    .foregroundColor(GlobalTheme.highlightGreen)
                                Text(section.name)
                                    .padding(.leading, 8)
                                Spacer()
                                Toggle("", isOn: $section.isActive)
                                    .labelsHidden()
                                    .padding(.trailing, 8)
                            }
                        }
                        .onMove { indices, newOffset in
                            sections.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                    .environment(\.editMode, $editMode)
                    .listStyle(.plain)
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(GlobalTheme.brandPrimary)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
    }
}

#Preview {
     DashboardView(
         showsIndicators: false,
         tabState: .constant(.visible),
         authService: AuthService()
     ) {
         Text("Dashboard Content")
     }
}

// Move this to file scope, outside any struct/extension
private let homeSectionsKey = "homeSectionsKey"

extension DashboardView {
    private func saveHomeSections() {
        if let data = try? JSONEncoder().encode(homeSections) {
            UserDefaults.standard.set(data, forKey: homeSectionsKey)
        }
    }

    private static func loadHomeSections() -> [HomeSection] {
        if let data = UserDefaults.standard.data(forKey: homeSectionsKey),
           let sections = try? JSONDecoder().decode([HomeSection].self, from: data) {
            return sections
        }
        // Default sections
        return [
            HomeSection(name: "Agenda", isActive: true, icon: "list.bullet.rectangle"),
            HomeSection(name: "Emails", isActive: true, icon: "envelope"),
            HomeSection(name: "Events", isActive: true, icon: "calendar"),
            HomeSection(name: "Campaigns", isActive: true, icon: "megaphone"),
            HomeSection(name: "Automations", isActive: true, icon: "bolt")
        ]
    }
}
