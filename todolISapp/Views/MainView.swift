//
//  ContentView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import SwiftUI
@_exported import Inject

struct MainView: View {
    @StateObject var viewModel = MainViewViewModel()
    @ObserveInjection var inject

    
    @ViewBuilder
    var accountView: some View {
        TabView{
            ToDoListView(userId: viewModel.currentUserId)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            RandomActivityView()
                .tabItem {
                    Label("Random", systemImage: "dice")
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
        .enableInjection()
    }
}

#Preview {
    MainView()
}
