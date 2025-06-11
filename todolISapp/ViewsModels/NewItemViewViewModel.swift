//
//  NewItemViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import Foundation

class NewItemViewViewModel: ObservableObject {
  @Published var title: String = ""
  @Published var dueDate = Date()
  @Published var showAlert: Bool = false

  init() {

  }
}
