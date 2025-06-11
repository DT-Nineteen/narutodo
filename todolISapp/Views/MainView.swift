@_exported import Inject
//
//  ContentView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import SwiftUI

struct MainView: View {
  @StateObject var viewModel = MainViewViewModel()
  @ObserveInjection var inject
  @EnvironmentObject var authViewModel: AuthService

  @ViewBuilder
  var accountView: some View {
    TabView {
      ToDoListView(viewModel: ToDoListViewViewModel(userId: "123"))
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
      if authViewModel.isAuthenticated {
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
