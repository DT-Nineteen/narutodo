//
//  RegisterView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import SwiftUI

struct RegisterView: View {
  @StateObject var viewModel = RegisterViewViewModel()

  var body: some View {
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
          Text("Register")
            .font(.system(size: 50, weight: .bold))
            .foregroundColor(.white)
        }
        .padding(.top, 40)
        .padding(.bottom, 60)

        Spacer()

        // Register Form Section
        VStack(spacing: 20) {
          // Full Name Field
          VStack(alignment: .leading, spacing: 8) {
            TextField("Full Name", text: $viewModel.full_name)
              .font(.system(size: 16))
              .foregroundColor(.primary)
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background(Color.white.opacity(0.9))
              .cornerRadius(8)
          }

          // Email Field
          VStack(alignment: .leading, spacing: 8) {
            TextField("Email Address", text: $viewModel.email)
              .font(.system(size: 16))
              .foregroundColor(.primary)
              .autocapitalization(.none)
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

          // Sign Up Button or Loading
          if viewModel.isLoading {
            ProgressView()
              .scaleEffect(1.2)
              .tint(.white)
              .padding(.vertical, 16)
          } else {
            Button(action: {
              viewModel.signUp()
            }) {
              Text("Sign Up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.top, 10)
          }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 60)

        Spacer()
      }
    }
    .alert(isPresented: $viewModel.showAlert) {
      Alert(
        title: Text("Notification"),
        message: Text(viewModel.alertMessage),
        dismissButton: .default(Text("OK"))
      )
    }
  }
}

#Preview {
  RegisterView()
}
