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
    VStack {
      //Header
      HeaderView(
        title: "Register", subtitle: "Start fill your todos", angle: -15, background: .green,
        paddingTop: 20)

      //Login Form
      Form {
        TextField("Full Name", text: $viewModel.full_name)
          .textFieldStyle(DefaultTextFieldStyle())
        TextField("Email Address", text: $viewModel.email)
          .autocapitalization(.none)
          .textFieldStyle(DefaultTextFieldStyle())
        SecureField("Password", text: $viewModel.password)
          .textFieldStyle(DefaultTextFieldStyle())
        viewModel.errorMessage.isEmpty
          ? nil
          : Text(viewModel.errorMessage).foregroundColor(Color.red).textFieldStyle(
            DefaultTextFieldStyle())
        if viewModel.isLoading {
          ProgressView()
        } else {
          TLButton(title: "Sign Up", background: .green) {
            viewModel.signUp()
          }.padding()
        }
      }.scrollContentBackground(.hidden).offset(y: -50)

      Spacer()
    }.alert(isPresented: $viewModel.showAlert) {
      Alert(
        title: Text("Notification"), message: Text(viewModel.alertMessage),
        dismissButton: .default(Text("OK")))
    }
  }
}

#Preview {
  RegisterView()
}
