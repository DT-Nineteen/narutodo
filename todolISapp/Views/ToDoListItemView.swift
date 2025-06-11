//
//  ToDoListItemView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import SwiftUI

struct ToDoListItemView: View {
  @StateObject var viewModel = ToDoListItemViewViewModel()
  let item: TodoListItem
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(item.title).font(.body)
        Text(
          "\(Date(timeIntervalSince1970: item.dueDate).formatted(date: .abbreviated, time: .shortened))"
        ).font(.footnote).foregroundColor(Color.gray)
      }

      Spacer()

      Button {
      } label: {
        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle").foregroundColor(.blue)
      }

    }
  }
}

#Preview {
  ToDoListItemView(
    item: .init(
      id: "123", title: "123", dueDate: Date().timeIntervalSince1970,
      createdDate: Date().timeIntervalSince1970, isDone: false))
}
