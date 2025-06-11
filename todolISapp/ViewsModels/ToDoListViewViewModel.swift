//
//  ToDoListViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
// import FirebaseFirestore // Replaced with Supabase
import Foundation

class ToDoListViewViewModel: ObservableObject {
  @Published var isShowNewItemView = false

  private let userId: String

  init(userId: String) {
    self.userId = userId
  }
}
