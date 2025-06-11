//
//  LoginViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import Foundation
import Supabase

class LoginViewViewModel: ObservableObject {
  @Published var email = ""
  @Published var password = ""
  @Published var errorMessage = ""
  @Published var isLoading = false
  @Published var showAlert = false
  @Published var alertMessage = ""

  init() {}

  func login() {
    errorMessage = ""
    guard validate() else {
      return
    }
    isLoading = true

    // Login
    Task {
      do {
        _ = try await SupabaseManager.shared.client.auth.signIn(
          email: email,
          password: password
        )

        alertMessage = "Login successful"
        showAlert = true
        isLoading = false
      } catch {
        showAlert = true
        isLoading = false
        print("❌ Login failed: \(error.localizedDescription)")
        alertMessage = "Login failed: \(error.localizedDescription)"
        showAlert = true
        isLoading = false
      }
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

    return true
  }

}
