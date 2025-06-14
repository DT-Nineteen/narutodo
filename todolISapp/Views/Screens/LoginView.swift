//
//  LoginView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import SwiftUI

struct LoginView: View {
  @StateObject var viewModel = LoginViewViewModel()

  var body: some View {
    NavigationView {
      ZStack {
        // Full screen gradient background
        LinearGradient(
          gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.1)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)

        VStack(spacing: 0) {
          // Header Section
          VStack(spacing: 12) {
            Text("Login")
              .font(.system(size: 50, weight: .bold))
              .foregroundColor(.white)
          }
          .padding(.top, 80)
          .padding(.bottom, 60)

          Spacer()

          // Login Form Section
          VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
              TextField("Email Address", text: $viewModel.email)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
            }

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
              SecureField("Password", text: $viewModel.password)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
            }

            // Error Message
            if !viewModel.errorMessage.isEmpty {
              Text(viewModel.errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .padding(.horizontal, 4)
            }

            // Login Button
            Button(action: {
              viewModel.login()
            }) {
              Text("Log In")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.top, 10)
          }
          .padding(.horizontal, 30)
          .padding(.bottom, 40)

          // Create Account Section
          VStack(spacing: 8) {
            Text("New here?")
              .font(.system(size: 16))
              .foregroundColor(.white.opacity(0.8))

            NavigationLink("Create Account", destination: RegisterView())
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.white)
          }
          .padding(.bottom, 50)

          Spacer()
        }
      }
    }
    .alert("Notification", isPresented: $viewModel.showAlert) {
      Button("OK") {}
    } message: {
      Text(viewModel.alertMessage)
    }
  }
}

#Preview {
  LoginView()
}
