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
            VStack{
                //Header
                HeaderView(title:"Register", subtitle: "Start fill your todos", angle: -15, background: .green, paddingTop: 20)
                            
                //Login Form
                Form {
                    TextField("Full Name", text: $viewModel.fullName)
                        .textFieldStyle(DefaultTextFieldStyle())
                    TextField("Email Address", text: $viewModel.email)
                        .textFieldStyle(DefaultTextFieldStyle())
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(DefaultTextFieldStyle())
                   
                    
                    TLButton(title: "Sign Up", background: .green){
                        viewModel.register()
                    }.padding()
                }.scrollContentBackground(.hidden).offset(y:-50)
                
                Spacer()
            }
    }
}

#Preview {
    RegisterView()
}
