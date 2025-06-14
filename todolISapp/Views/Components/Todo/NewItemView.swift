//
//  NewItemView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import SwiftUI

struct NewItemView: View {
  @StateObject var viewModel = NewItemViewViewModel()
  @Binding var newItemPresented: Bool
  var body: some View {
    VStack {
      Text("New Item")
        .font(.system(size: 32)).bold().padding(.top, 80)

      Form {
        //Title
        TextField("Title", text: $viewModel.title)
          .textFieldStyle(DefaultTextFieldStyle())
          .autocapitalization(.none)
          .disableAutocorrection(true)

        //Due date
        DatePicker("Due Date", selection: $viewModel.dueDate)
          .datePickerStyle(GraphicalDatePickerStyle())
        //Button
        // TLButton(title: "Save", background: .pink){
        //     if( viewModel.canSave){
        //         viewModel.save()
        //         newItemPresented = false
        //     } else {
        //         viewModel.showAlert = true
        //     }
        // }.padding()
      }
    }.alert(isPresented: $viewModel.showAlert) {
      Alert(title: Text("Error"), message: Text("Fill all Field, and not chose date from past"))
    }
  }
}

#Preview {
  NewItemView(newItemPresented: Binding(get: { return true }, set: { _ in }))
}
