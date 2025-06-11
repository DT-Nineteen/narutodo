//
//  ToDoListItemsView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import SwiftUI

struct ToDoListView: View {
  @StateObject var viewModel: ToDoListViewViewModel

  var body: some View {
    NavigationView {

    }
  }
}

#Preview {
  ToDoListView(viewModel: ToDoListViewViewModel(userId: "FC123681-D157-4081-908E-B90C6F663973"))
}
