import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SebhaViewModel()
    @State private var delegate: SebhaViewModelDelegateClass?
    @State private var selectedTab: Tab = .home
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground).opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main Content
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView(viewModel: viewModel)
                        case .sebhas:
                            SebhasView(viewModel: viewModel)
                        case .profile:
                            ProfileView(viewModel: viewModel)
                        case .friends:
                            FriendsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom Tab Bar
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("🎉 Congratulations!"),
                message: Text("You have completed your target of \(viewModel.currentTarget) for \(viewModel.selectedSebha)!"),
                dismissButton: .default(Text("Continue")) {
                    // Alert dismissed, auto-switching handled in ViewModel
                }
            )
        }
        .onAppear {
            delegate = SebhaViewModelDelegateClass(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
