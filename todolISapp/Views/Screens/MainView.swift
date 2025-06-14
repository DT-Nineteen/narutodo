@_exported import Inject
import SwiftUI

struct MainView: View {
  @StateObject var viewModel = MainViewViewModel()
  @ObserveInjection var inject
  @EnvironmentObject var authViewModel: AuthService

  @ViewBuilder
  var accountView: some View {
    TabView {
      TodoListView()
        .tabItem {
          Label("", systemImage: "house")
        }

      RandomActivityView()
        .tabItem {
          Label("", systemImage: "dice")
        }

      ProfileView()
        .tabItem {
          Label("", systemImage: "person.circle")
        }
    }
  }

  // Loading view for authentication check
  @ViewBuilder
  var loadingView: some View {
    ZStack {
      // Full screen gradient background
      LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.1)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea(.all)

      VStack(spacing: 20) {
        ProgressView()
          .scaleEffect(1.5)
          .tint(.white)

        Text("Checking authentication...")
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.8))
      }
    }
  }

  var body: some View {
    VStack {
      if authViewModel.isLoading {
        // Show loading while checking authentication
        loadingView
      } else if authViewModel.isAuthenticated {
        // User is signed in - show main app
        accountView
      } else {
        // User is not signed in - show login
        LoginView()
      }
    }
    .enableInjection()
  }
}

#Preview {
  MainView()
}
