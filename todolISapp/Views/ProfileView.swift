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
            VStack{
                if let user = viewModel.user{
                    //Avatar
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color.blue)
                        .frame(width: 125, height: 125)
                        .padding()
                    
                    // Info
                    VStack{
                        HStack {
                            Text("Name: ").bold()
                            Text(user.name)
                        }.padding()
                        HStack {
                            Text("Email: ").bold()
                            Text(user.email)
                        }.padding()
                        HStack {
                            Text("Member since: ").bold()
                            Text("\(Date(timeIntervalSince1970: user.joined).formatted(date: .abbreviated, time: .shortened)).")
                        }.padding()
                       
                    }.padding()
                    
                    // Log out
                    Button("Log Out"){
                        viewModel.logOut()
                    }.tint(.red).padding()
                    
                    Spacer()
                }else{
                    Text("Loading Profile....")
                }
            }.navigationTitle("Profile")
        }.onAppear{viewModel.fetchUser()}
    }
}

#Preview {
    ProfileView()
}
