import SwiftUI

@main
struct todolISappApp: App {
  // Use @StateObject to create a single instance of AuthViewModel
  // It will exist throughout the lifetime of the application.
  @StateObject private var authViewModel = AuthService()

  init() {
  }

  var body: some Scene {
    WindowGroup {
      MainView().environmentObject(authViewModel)
    }
  }
}
