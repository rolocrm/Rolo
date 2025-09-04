import SwiftUI

struct Notification: Identifiable {
    let id = UUID()
    let title: String
    let timeAgo: String
    var isUnread: Bool
    let iconName: String
    let iconColor: Color
    let backgroundColor: Color
}

struct NotificationGroup: Identifiable {
    let id = UUID()
    let title: String
    var notifications: [Notification]
    var isExpanded: Bool = true
}

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMenu = false
    @State private var notificationGroups: [NotificationGroup] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Notification List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach($notificationGroups) { $group in
                                NotificationGroupView(group: $group)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Bottom text
                    bottomTextView
                }
                
                // Overlay menu
                if showMenu {
                    menuOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadNotifications()
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(GlobalTheme.brandPrimary)
            }
            
            Spacer()
            
            Text("Notifications")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(GlobalTheme.brandPrimary)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMenu.toggle()
                }
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(GlobalTheme.brandPrimary)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .background(Color.white)
    }
    
    private var bottomTextView: some View {
        Text("Only showing notifications of the last 30 days")
            .font(.system(size: 14))
            .foregroundColor(GlobalTheme.roloLightGrey)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
    }
    
    private var menuOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Notification settings button
                    Button(action: {
                        // TODO: Navigate to notification settings
                        showMenu = false
                    }) {
                        HStack {
                            Text("Notification settings")
                                .font(.system(size: 16))
                                .foregroundColor(GlobalTheme.brandPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundColor(GlobalTheme.brandPrimary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 17)
                        .frame(width: 278, height: 56)
                    }
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(GlobalTheme.roloLightGrey),
                        alignment: .bottom
                    )
                    
                    // Mark all as read button
                    Button(action: {
                        markAllAsRead()
                        showMenu = false
                    }) {
                        HStack {
                            Text("Mark all as read")
                                .font(.system(size: 16))
                                .foregroundColor(GlobalTheme.brandPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 20))
                                .foregroundColor(GlobalTheme.brandPrimary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 17)
                        .frame(width: 278, height: 56)
                    }
                    .background(Color.white)
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.15), radius: 28.4, x: 0, y: 4)
                .offset(y: 60)
                
                Spacer()
            }
            .padding(.trailing, 20)
            
            Spacer()
        }
        .background(
            Color.black.opacity(0.001)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showMenu = false
                    }
                }
        )
    }
    
    private func loadNotifications() {
        // Sample data - replace with actual data from your backend
        notificationGroups = [
            NotificationGroup(
                title: "Today",
                notifications: [
                    Notification(
                        title: "David is requesting to join your team",
                        timeAgo: "6 hr",
                        isUnread: true,
                        iconName: "person.2.badge.gearshape",
                        iconColor: GlobalTheme.highlightGreen,
                        backgroundColor: GlobalTheme.tertiaryGreen
                    ),
                    Notification(
                        title: "You have 4 tasks on your agenda today.",
                        timeAgo: "8 hr",
                        isUnread: false,
                        iconName: "sun.max",
                        iconColor: GlobalTheme.roloLightGrey,
                        backgroundColor: GlobalTheme.inputGrey
                    )
                ]
            ),
            NotificationGroup(
                title: "This week",
                notifications: [
                    Notification(
                        title: "Nechama completed a task assigned to her",
                        timeAgo: "2 d",
                        isUnread: false,
                        iconName: "checkmark.circle",
                        iconColor: GlobalTheme.roloLightGrey,
                        backgroundColor: GlobalTheme.inputGrey
                    ),
                    Notification(
                        title: "Connect to Stripe",
                        timeAgo: "4 d",
                        isUnread: false,
                        iconName: "exclamationmark.circle",
                        iconColor: GlobalTheme.roloLightGrey,
                        backgroundColor: GlobalTheme.inputGrey
                    )
                ]
            ),
            NotificationGroup(
                title: "This month",
                notifications: [
                    Notification(
                        title: "You have 4 tasks on your agenda today.",
                        timeAgo: "23 d",
                        isUnread: false,
                        iconName: "sun.max",
                        iconColor: GlobalTheme.roloLightGrey,
                        backgroundColor: GlobalTheme.inputGrey
                    )
                ]
            )
        ]
    }
    
    private func markAllAsRead() {
        for groupIndex in notificationGroups.indices {
            for notificationIndex in notificationGroups[groupIndex].notifications.indices {
                notificationGroups[groupIndex].notifications[notificationIndex].isUnread = false
            }
        }
    }
}

struct NotificationGroupView: View {
    @Binding var group: NotificationGroup
    
    var body: some View {
        VStack(spacing: 10) {
            // Group header
            HStack {
                Text(group.title)
                    .font(.system(size: 16))
                    .foregroundColor(GlobalTheme.roloLightGrey)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Notifications
            VStack(spacing: 0) {
                ForEach(group.notifications) { notification in
                    NotificationRowView(notification: notification)
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: Notification
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.backgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(notification.iconColor)
            }
            .padding(.leading, 20)
            
            // Content
            HStack {
                Text(notification.title)
                    .font(.system(size: 16))
                    .foregroundColor(GlobalTheme.brandPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Text(notification.timeAgo)
                    .font(.system(size: 14))
                    .foregroundColor(GlobalTheme.roloLightGrey)
            }
            .padding(.trailing, 20)
        }
        .frame(height: 60)
        .background(notification.isUnread ? GlobalTheme.tertiaryGreen : Color.white)
    }
}

#Preview {
    let sampleNotifications = [
        NotificationGroup(
            title: "Today",
            notifications: [
                Notification(
                    title: "David is requesting to join your team",
                    timeAgo: "6 hr",
                    isUnread: true,
                    iconName: "person.2.badge.gearshape",
                    iconColor: GlobalTheme.highlightGreen,
                    backgroundColor: GlobalTheme.tertiaryGreen
                ),
                Notification(
                    title: "You have 4 tasks on your agenda today.",
                    timeAgo: "8 hr",
                    isUnread: false,
                    iconName: "sun.max",
                    iconColor: GlobalTheme.roloLightGrey,
                    backgroundColor: GlobalTheme.inputGrey
                )
            ]
        ),
        NotificationGroup(
            title: "This week",
            notifications: [
                Notification(
                    title: "Nechama completed a task assigned to her",
                    timeAgo: "2 d",
                    isUnread: false,
                    iconName: "checkmark.circle",
                    iconColor: GlobalTheme.roloLightGrey,
                    backgroundColor: GlobalTheme.inputGrey
                ),
                Notification(
                    title: "Connect to Stripe",
                    timeAgo: "4 d",
                    isUnread: false,
                    iconName: "exclamationmark.circle",
                    iconColor: GlobalTheme.roloLightGrey,
                    backgroundColor: GlobalTheme.inputGrey
                )
            ]
        ),
        NotificationGroup(
            title: "This month",
            notifications: [
                Notification(
                    title: "You have 4 tasks on your agenda today.",
                    timeAgo: "23 d",
                    isUnread: false,
                    iconName: "sun.max",
                    iconColor: GlobalTheme.roloLightGrey,
                    backgroundColor: GlobalTheme.inputGrey
                )
            ]
        )
    ]
    
    return NavigationView {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(GlobalTheme.brandPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Notifications")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(GlobalTheme.brandPrimary)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(GlobalTheme.brandPrimary)
                            .rotationEffect(.degrees(90))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(Color.white)
                
                // Notification List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sampleNotifications) { group in
                            NotificationGroupView(group: .constant(group))
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                // Bottom text
                Text("Only showing notifications of the last 30 days")
                    .font(.system(size: 14))
                    .foregroundColor(GlobalTheme.roloLightGrey)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
    }
    .navigationBarHidden(true)
} 
