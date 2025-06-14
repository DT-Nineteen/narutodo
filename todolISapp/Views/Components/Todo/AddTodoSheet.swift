import SwiftUI

struct AddTodoSheet: View {
  @EnvironmentObject private var viewModel: TodoViewModel
  @Binding var isPresented: Bool
  @State private var todoTitle = ""
  @State private var dueDate = Date()
  @State private var showAlert = false

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Title section
        Text("New Todo")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.top, 20)

        Form {
          // Title field
          Section("Title") {
            TextField("Todo title", text: $todoTitle)
              .textFieldStyle(DefaultTextFieldStyle())
              .autocapitalization(.none)
              .disableAutocorrection(true)
          }

          // Due date section
          Section("Due Date") {
            DatePicker("Due Date", selection: $dueDate)
              .datePickerStyle(GraphicalDatePickerStyle())
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        // Cancel button
        ToolbarItemGroup(placement: .cancellationAction) {
          Button("Cancel") {
            print("[DEBUG] Add todo cancelled")
            isPresented = false
          }
        }

        // Add button
        ToolbarItemGroup(placement: .confirmationAction) {
          Button("Add") {
            saveTodo()
          }
          .disabled(!canSave)
        }
      }
      .alert("Error", isPresented: $showAlert) {
        Button("OK") {}
      } message: {
        Text("Please fill in the title and ensure the due date is not in the past.")
      }
    }
  }

  // Validation logic
  private var canSave: Bool {
    let trimmedTitle = todoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    let isValidDate = dueDate >= Calendar.current.startOfDay(for: Date())

    print("[DEBUG] Can save new todo: title='\(trimmedTitle)', isValidDate=\(isValidDate)")
    return !trimmedTitle.isEmpty && isValidDate
  }

  // Save todo function
  private func saveTodo() {
    guard canSave else {
      print("[DEBUG] Cannot save new todo - validation failed")
      showAlert = true
      return
    }

    print("[DEBUG] Creating new todo: \(todoTitle), due: \(dueDate)")

    Task {
      await viewModel.addTodo(
        title: todoTitle.trimmingCharacters(in: .whitespacesAndNewlines),
        dueDate: dueDate
      )
      isPresented = false
    }
  }
}

// MARK: - Preview
#Preview {
  AddTodoSheet(isPresented: .constant(true))
    .environmentObject(TodoViewModel())
}
