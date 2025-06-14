import Combine
import Foundation
import Supabase

@MainActor  // This is needed to update the UI on the main thread
class AuthService: ObservableObject {

  @Published var isAuthenticated: Bool = false
  @Published var currentSession: Session?
  @Published var isLoading: Bool = true  // Add loading state for better UX

  init() {
    // Check initial session first, then start listening
    checkInitialSession()
    startListeningToAuthEvents()
  }

  // the supabase client is used to interact with the supabase database
  private let supabase = SupabaseManager.shared.client

  // This is used to listen to the auth state changes
  private var authStateTask: Task<Void, Never>? = nil

  // MARK: - Initial Session Check
  private func checkInitialSession() {
    Task {
      do {
        // Try to get current session from Supabase
        let session = try await supabase.auth.session

        // Update UI on main thread
        await MainActor.run {
          self.currentSession = session
          self.isAuthenticated = true
          self.isLoading = false
          print("✅ Initial session found: \(session.user.email ?? "No email")")
        }
      } catch {
        // No session found or error occurred
        await MainActor.run {
          self.currentSession = nil
          self.isAuthenticated = false
          self.isLoading = false
          print("🛑 No initial session found: \(error.localizedDescription)")
        }
      }
    }
  }

  func startListeningToAuthEvents() {
    // Assign task to manage its lifecycle
    authStateTask = Task {
      // Core logic: Listen to authStateChanges
      // An asynchronous event stream.
      for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {

        // Handle each event
        switch event {
        case .signedIn, .initialSession:
          // When the user logs in or has an existing session
          self.currentSession = session
          self.isAuthenticated = true
          self.isLoading = false
          print("✅ User is SIGNED IN: \(session?.user.email ?? "No email")")

        case .signedOut:
          // When the user logs out
          self.currentSession = nil
          self.isAuthenticated = false
          self.isLoading = false
          print("🛑 User is SIGNED OUT")

        case .tokenRefreshed:
          // Supabase automatically refreshes the token, you can do nothing here
          // but it's useful for debugging.
          self.currentSession = session
          self.isAuthenticated = true
          print("♻️ Token has been refreshed")

        case .userUpdated:
          // Update session if user information changes
          self.currentSession = session
          print("👤 User updated: \(session?.user.email ?? "No email")")

        case .passwordRecovery:
          // This is used to redirect the user to the password reset screen
          print("✨ Password recovery event received")
        default:
          print("❓ Unknown auth event: \(event)")
        }
      }
    }
  }

  deinit {
    // Cancel the task when the ViewModel is deinitialized to prevent memory leaks
    authStateTask?.cancel()
  }
}
