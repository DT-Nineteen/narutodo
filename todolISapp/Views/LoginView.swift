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
            VStack{
                //Header
                HeaderView(title:"To Do List", subtitle: "Get things done", angle: 15, background: .blue, paddingTop: 80)
               
                //Login Form
                Form {
                   
                    TextField("Email Address", text: $viewModel.email)
                        .textFieldStyle(DefaultTextFieldStyle())
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(DefaultTextFieldStyle())
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage).foregroundColor(Color.red).listRowSeparator(.hidden)
                    }

                    TLButton(title: "Log In", background: .blue){
                        viewModel.login()
                    }.padding()
                    
                   
                }.scrollContentBackground(.hidden)
                
                //Create Account
                VStack{
                    Text("New here?")
                    NavigationLink("Create Account", destination: RegisterView())
                }.padding(.bottom, 50)
                
                Spacer()
            }
        }
    }
}

#Preview {
    LoginView()
}
