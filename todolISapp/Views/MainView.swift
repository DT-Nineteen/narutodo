//
//  ContentView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewViewModel()
    
    @ViewBuilder
    var accountView: some View {
        TabView{
            ToDoListView(userId: viewModel.currentUserId)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
    
    var body: some View {
        VStack {
            if viewModel.isSignedIn, !viewModel.currentUserId.isEmpty {
                //Signed In
                accountView
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    MainView()
}
