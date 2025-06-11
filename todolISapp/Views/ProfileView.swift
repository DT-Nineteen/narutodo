//
//  ProfileView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import SwiftUI

struct ProfileView: View {
  @StateObject var viewModel = ProfileViewViewModel()

  var body: some View {
    NavigationView {
      VStack {
        if let user = viewModel.userProfile {
          //Avatar
          Image(systemName: "person.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Color.blue)
            .frame(width: 125, height: 125)
            .padding()

          // Info
          VStack {
            HStack {
              Text("Name: ").bold()
              Text(user.fullName ?? "")
            }.padding()
            HStack {
              Text("Email: ").bold()
              Text(user.email ?? "")
            }.padding()
          }.padding()

          // Log out
          Button("Log Out") {
            Task {
              await viewModel.logOut()
            }
          }.tint(.red).padding()

          Spacer()
        } else {
          Text("Loading Profile....")
          Button("Log Out") {
            Task {
              await viewModel.logOut()
            }
          }.tint(.red).padding()
        }
      }.navigationTitle("Profile")
    }.onAppear {
      Task {
        await viewModel.fetchCurrentUserProfile()
      }
    }
  }
}

#Preview {
  ProfileView()
}
