import SwiftUI


struct HomeView: View {
    @ObservedObject var authService: AuthService
    @State private var selectedTab = "dashbaordTab"
    
    /// View Properties
    @State private var tabState: Visibility = .visible
    
    @State private var isPresentingAddMember: Bool = false
    @State private var showingEditCommunity = false
    
    init(authService: AuthService) {
        self.authService = authService
        UITabBar.appearance().unselectedItemTintColor = UIColor(GlobalTheme.roloLightGrey)
    }
    


    var body: some View {
        TabView (selection: $selectedTab) {
            DashboardView(axis: .vertical, showsIndicators: false, tabState: $tabState, authService: authService) {
                
            }
            .toolbar(tabState, for: .tabBar)
            .animation(.easeInOut(duration: 0.3), value: tabState)
                .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                }
                .tag("dashbaordTab")
                .toolbarBackground(.white.opacity(0.4), for: .tabBar)

            
                
            MemberListView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Members")
                }
                .tag("membersTab")
                .toolbarBackground(.white, for: .tabBar)
            
            Text("Automations View")
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Automation")
                }
                .tag("automationsTab")
                .toolbarBackground(.white, for: .tabBar)
                
            Text("Events View")
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag("eventsTab")
                .toolbarBackground(.white, for: .tabBar)
                
            AccountView(authService: authService, showingEditCommunity: $showingEditCommunity)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Account")
                }
                .tag("accountTab")
                .toolbarBackground(.white, for: .tabBar)
        }
        .accentColor(GlobalTheme.brandPrimary)
        .sheet(isPresented: $showingEditCommunity) {
            EditCommunityView(
                authService: authService,
                isPresented: $showingEditCommunity
            )
        }
    }
}



#Preview {
    HomeView(authService: AuthService())
}



