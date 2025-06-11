import Foundation
import Supabase

class RegisterViewViewModel: ObservableObject {
  @Published var email = ""
  @Published var password = ""
  @Published var errorMessage = ""
  @Published var showAlert = false
  @Published var isLoading = false
  @Published var alertMessage = ""
  @Published var full_name = ""

  init() {}

  func signUp() {
    errorMessage = ""
    guard validate() else {
      return
    }
    isLoading = true

    // Use Task to perform asynchronous work
    Task {
      do {
        // Call the signUp function from Supabase client
        let session = try await SupabaseManager.shared.client.auth.signUp(
          email: email,
          password: password,
          data: ["full_name": .string(full_name)]
        )

        // Handle the result
        print("Sign up successful, session: \(session)")
        alertMessage = "Sign up successful! Now you can login to your account."

      } catch {
        // Handle the error
        print("Error signing up: \(error.localizedDescription)")
        alertMessage = "An error occurred: \(error.localizedDescription)"
      }

      // Update the UI after completion
      isLoading = false
      showAlert = true
    }
  }

  private func validate() -> Bool {
    guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
      !password.trimmingCharacters(in: .whitespaces).isEmpty
    else {
      errorMessage = "Can not be empty"
      return false
    }

    // email@xxx.com
    guard email.contains("@") && email.contains(".") else {
      errorMessage = "Invalid Email"
      return false
    }

    // 123456
    guard password.count >= 6 else {
      errorMessage = "Invalid Passwrod"
      return false
    }

    return true
  }
}
