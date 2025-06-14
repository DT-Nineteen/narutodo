import SwiftUI

struct EditTodoSheet: View {
  @EnvironmentObject private var viewModel: TodoViewModel
  @Binding var isPresented: Bool

  let todo: Todo
  @State private var todoTitle: String
  @State private var dueDate: Date
  @State private var showAlert = false

  // Debug logs and comments for easier debugging & readability
  init(isPresented: Binding<Bool>, todo: Todo) {
    self._isPresented = isPresented
    self.todo = todo
    self._todoTitle = State(initialValue: todo.title)
    self._dueDate = State(initialValue: todo.dueDate ?? Date())

    print("[DEBUG] EditTodoSheet initialized for todo: \(todo.title)")
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Title section
        Text("Edit Todo")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.top, 20)

        Form {
          // Title field
          Section("Title") {
            TextField("Todo title", text: $todoTitle)
              .textFieldStyle(DefaultTextFieldStyle())
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
            print("[DEBUG] Edit todo cancelled")
            isPresented = false
          }
        }

        // Save button
        ToolbarItemGroup(placement: .confirmationAction) {
          Button("Save") {
            saveChanges()
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

    print("[DEBUG] Can save: title='\(trimmedTitle)', isValidDate=\(isValidDate)")
    return !trimmedTitle.isEmpty && isValidDate
  }

  // Save changes function
  private func saveChanges() {
    guard canSave else {
      print("[DEBUG] Cannot save - validation failed")
      showAlert = true
      return
    }

    print("[DEBUG] Saving todo changes: \(todoTitle), due: \(dueDate)")

    Task {
      await viewModel.updateTodo(
        todo: todo,
        newTitle: todoTitle.trimmingCharacters(in: .whitespacesAndNewlines),
        newDueDate: dueDate
      )
      isPresented = false
    }
  }
}

// MARK: - Preview
#Preview {
  EditTodoSheet(
    isPresented: .constant(true),
    todo: Todo(
      id: UUID(),
      title: "Sample Todo",
      isCompleted: false,
      createdAt: Date(),
      dueDate: Date(),
      activityId: nil
    )
  )
  .environmentObject(TodoViewModel())
}
