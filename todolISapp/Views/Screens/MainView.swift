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
          Label("Home", systemImage: "house")
        }

      RandomActivityView()
        .tabItem {
          Label("Random", systemImage: "dice")
        }

      ProfileView()
        .tabItem {
          Label("Profile", systemImage: "person.circle")
        }
    }
  }

  var body: some View {

    VStack {
      if authViewModel.isAuthenticated {
        //Signed In
        accountView
      } else {
        LoginView()
      }
    }
    .enableInjection()
  }
}

#Preview {
  MainView()
}
