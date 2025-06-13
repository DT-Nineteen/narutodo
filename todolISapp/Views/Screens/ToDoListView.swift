import SwiftUI

struct TodoListView: View {
  @EnvironmentObject private var viewModel: TodoViewModel
  @State private var isAddingTodo = false
  @State private var editingTodo: Todo?
  @State private var showingEditSheet = false

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Filter Section
        FilterSection()

        // Calendar Filter Info (when calendar filter is active)
        if viewModel.selectedFilter == .calendar, let selectedDate = viewModel.selectedCalendarDate
        {
          CalendarFilterInfo(selectedDate: selectedDate)
        }

        // Main Content
        if viewModel.filteredTodos.isEmpty {
          EmptyStateView(
            filter: viewModel.selectedFilter, selectedDate: viewModel.selectedCalendarDate)
        } else {
          List {
            ForEach(viewModel.filteredTodos) { todo in
              TodoRowView(
                todo: todo,
                viewModel: viewModel,
                onEdit: {
                  editingTodo = todo
                  showingEditSheet = true
                }
              )
            }
            .onDelete { indexSet in
              Task {
                await viewModel.deleteTodo(at: indexSet)
              }
            }
          }
          .listStyle(.plain)
          .refreshable {
            await viewModel.fetchTodos()
          }
        }

        // Add Todo Button
        AddTodoButton(isAddingTodo: $isAddingTodo)
      }
      .navigationTitle("My Todos")
      .task {
        viewModel.isLoading = true
        await viewModel.fetchTodos()
        viewModel.isLoading = false
      }
      .overlay {
        if viewModel.isLoading {
          LoadingView()
        }
      }
      .sheet(isPresented: $isAddingTodo) {
        AddTodoSheet(isPresented: $isAddingTodo)
      }
      .sheet(isPresented: $showingEditSheet) {
        if let todo = editingTodo {
          EditTodoSheet(isPresented: $showingEditSheet, todo: todo)
        }
      }
      .sheet(isPresented: $viewModel.showCalendarPicker) {
        CalendarFilterView(isPresented: $viewModel.showCalendarPicker)
      }
      .alert("Error", isPresented: $viewModel.showErrorAlert) {
        Button("OK") {
          viewModel.clearError()
        }
      } message: {
        Text(viewModel.errorMessage ?? "An unexpected error occurred.")
      }
    }
  }
}

// Calendar Filter Info Bar
private struct CalendarFilterInfo: View {
  let selectedDate: Date
  @EnvironmentObject private var viewModel: TodoViewModel

  var body: some View {
    HStack {
      Image(systemName: "calendar.circle.fill")
        .foregroundColor(.accentColor)

      Text("Filtering by: \(formatDate(selectedDate))")
        .font(.subheadline)
        .fontWeight(.medium)

      Spacer()

      Button("Clear") {
        viewModel.clearCalendarFilter()
      }
      .font(.caption)
      .foregroundColor(.accentColor)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(Color.accentColor.opacity(0.1))
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
}

// Filter Section
private struct FilterSection: View {
  @EnvironmentObject private var viewModel: TodoViewModel

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(TodoFilter.allCases, id: \.self) { filter in
          FilterChip(
            title: getFilterDisplayTitle(for: filter),
            isSelected: viewModel.selectedFilter == filter,
            count: getFilterCount(for: filter)
          ) {
            viewModel.setFilter(filter)
          }
        }
      }
      .padding(.horizontal)
    }
    .padding(.vertical, 8)
    .background(Color(.systemGroupedBackground))
  }

  // Get display title for filter (special handling for calendar)
  private func getFilterDisplayTitle(for filter: TodoFilter) -> String {
    if filter == .calendar, let selectedDate = viewModel.selectedCalendarDate {
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM d"
      return formatter.string(from: selectedDate)
    }
    return filter.displayName
  }

  private func getFilterCount(for filter: TodoFilter) -> Int {
    switch filter {
    case .all:
      return viewModel.todos.count
    case .today:
      return viewModel.todos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
      }.count
    case .tomorrow:
      return viewModel.todos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
      }.count
    case .overdue:
      return viewModel.todos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date()) && !todo.isCompleted
      }.count
    case .thisWeek:
      return viewModel.todos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
          return false
        }
        return weekInterval.contains(dueDate)
      }.count
    case .calendar:
      guard let selectedDate = viewModel.selectedCalendarDate else { return 0 }
      return viewModel.todos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
      }.count
    default:
      return 0
    }
  }
}

// Filter Chip Component
private struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let count: Int
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Text(title)
          .font(.caption)
          .fontWeight(.medium)

        if count > 0 {
          Text("(\(count))")
            .font(.caption2)
            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? Color.accentColor : Color(.systemGray5))
      )
      .foregroundColor(isSelected ? .white : .primary)
    }
  }
}

// Subviews
private struct TodoRowView: View {
  let todo: Todo
  @ObservedObject var viewModel: TodoViewModel
  let onEdit: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        // Checkbox
        Button(action: {
          Task {
            await viewModel.toggleTodoStatus(todo: todo)
          }
        }) {
          Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            .foregroundColor(todo.isCompleted ? .green : .secondary)
            .font(.title3)
        }

        // Todo Title
        Text(todo.title)
          .strikethrough(todo.isCompleted)
          .foregroundColor(todo.isCompleted ? .secondary : .primary)
          .font(.body)

        Spacer()

        // Activity Badge (if from activity)
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
        .padding(.leading, 32)  // Align with title
      }
    }
    .contentShape(Rectangle())
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      // Edit button
      Button("Edit") {
        onEdit()
      }
      .tint(.blue)

      // Delete button
      Button(role: .destructive) {
        if let index = viewModel.filteredTodos.firstIndex(where: { $0.id == todo.id }) {
          Task {
            await viewModel.deleteTodo(at: IndexSet([index]))
          }
        }
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }

  private func formatDueDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()

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

private struct EmptyStateView: View {
  let filter: TodoFilter
  let selectedDate: Date?

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: getEmptyIcon())
        .font(.system(size: 50))
        .foregroundColor(.secondary)

      Text(getEmptyTitle())
        .font(.title3)
        .fontWeight(.medium)

      Text(getEmptyMessage())
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
  }

  private func getEmptyIcon() -> String {
    switch filter {
    case .overdue:
      return "exclamationmark.triangle"
    case .calendar:
      return "calendar"
    default:
      return "checklist"
    }
  }

  private func getEmptyTitle() -> String {
    switch filter {
    case .all:
      return "No Todos Yet"
    case .today:
      return "No Todos for Today"
    case .tomorrow:
      return "No Todos for Tomorrow"
    case .overdue:
      return "No Overdue Todos"
    case .thisWeek:
      return "No Todos This Week"
    case .calendar:
      if let date = selectedDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "No Todos for \(formatter.string(from: date))"
      }
      return "No Todos for Selected Date"
    }
  }

  private func getEmptyMessage() -> String {
    switch filter {
    case .all:
      return "Add your first todo to get started!"
    case .today:
      return "You're all caught up for today!"
    case .tomorrow:
      return "Nothing scheduled for tomorrow yet."
    case .overdue:
      return "Great! No overdue tasks."
    case .thisWeek:
      return "No todos scheduled for this week."
    case .calendar:
      return "No todos due on this date."
    }
  }
}

private struct LoadingView: View {
  var body: some View {
    ZStack {
      Color.black.opacity(0.2)

      ProgressView()
        .scaleEffect(1.5)
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    .ignoresSafeArea()
  }
}

private struct AddTodoButton: View {
  @Binding var isAddingTodo: Bool

  var body: some View {
    Button(action: { isAddingTodo = true }) {
      HStack {
        Image(systemName: "plus.circle.fill")
        Text("Add Todo")
      }
      .font(.headline)
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(Color.accentColor)
      .cornerRadius(10)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
}

// Preview
#Preview {
  TodoListView()
    .environmentObject(TodoViewModel())
}
