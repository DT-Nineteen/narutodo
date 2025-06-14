import SwiftUI

struct ToDoView: View {
  let todo: Todo
  let onToggle: (Todo) -> Void
  let onEdit: ((Todo) -> Void)?

  // Debug logs and comments for easier debugging & readability
  init(todo: Todo, onToggle: @escaping (Todo) -> Void, onEdit: ((Todo) -> Void)? = nil) {
    self.todo = todo
    self.onToggle = onToggle
    self.onEdit = onEdit
    print("[DEBUG] ToDoView initialized for: \(todo.title)")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        // Completion toggle button
        Button(action: {
          print("[DEBUG] Toggle todo: \(todo.id)")
          onToggle(todo)
        }) {
          Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            .foregroundColor(todo.isCompleted ? .green : .secondary)
            .font(.title3)
        }

        // Todo title
        Text(todo.title)
          .strikethrough(todo.isCompleted)
          .foregroundColor(todo.isCompleted ? .secondary : .primary)
          .lineLimit(2)
          .padding(.leading, 4)
          .font(.body)

        Spacer()

        // Activity badge if from activity
        if todo.activityId != nil {
          Image(systemName: "dice.fill")
            .foregroundColor(.blue)
            .font(.caption)
        }

      }

      // Due Date Info
      if let dueDate = todo.dueDate {
        HStack {
          Image(systemName: "calendar")
            .font(.caption2)
            .foregroundColor(.secondary)

          Text(formatDueDate(dueDate))
            .font(.caption)
            .foregroundColor(getDueDateColor(dueDate))
        }
        .padding(.leading, 32)
      }
    }
    .padding(.vertical, 2)
    .contentShape(Rectangle())
    .onTapGesture {
      print("[DEBUG] Tapped todo: \(todo.title)")
    }
  }

  // Format due date for display
  private func formatDueDate(_ date: Date) -> String {
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
      return "Due today"
    } else if calendar.isDateInTomorrow(date) {
      return "Due tomorrow"
    } else if calendar.isDateInYesterday(date) {
      return "Was due yesterday"
    } else {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .none
      return "Due \(formatter.string(from: date))"
    }
  }

  // Get color for due date based on urgency
  private func getDueDateColor(_ date: Date) -> Color {
    let calendar = Calendar.current
    let now = Date()

    if date < calendar.startOfDay(for: now) && !todo.isCompleted {
      return .red  // Overdue
    } else if calendar.isDateInToday(date) {
      return .orange  // Due today
    } else {
      return .secondary  // Future dates
    }
  }
}

// MARK: - Preview
#Preview {
  VStack(spacing: 16) {
    // Todo with due date (today)
    ToDoView(
      todo: Todo(
        id: UUID(),
        title: "Sample Todo Due Today",
        isCompleted: false,
        createdAt: Date(),
        dueDate: Date(),
        activityId: nil
      ),
      onToggle: { _ in },
      onEdit: { _ in }
    )

    // Todo without due date
    ToDoView(
      todo: Todo(
        id: UUID(),
        title: "Sample Todo Without Due Date",
        isCompleted: true,
        createdAt: Date(),
        dueDate: nil,
        activityId: nil
      ),
      onToggle: { _ in }
    )

    // Todo from activity
    ToDoView(
      todo: Todo(
        id: UUID(),
        title: "Activity Generated Todo",
        isCompleted: false,
        createdAt: Date(),
        dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
        activityId: UUID()
      ),
      onToggle: { _ in },
      onEdit: { _ in }
    )
  }
}
