import SwiftUI

struct TodoListView: View {
  @EnvironmentObject private var viewModel: TodoViewModel
  @State private var isAddingTodo = false
  @State private var editingTodo: Todo?
  @State private var showingEditSheet = false

  var body: some View {
    NavigationView {
      ZStack {

        // Full screen gradient background
        LinearGradient(
          gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.1)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)

        VStack(spacing: 0) {
          Text("Do! Or be done")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
            .overlay(
              Text("Do! Or be done")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.blue.opacity(0.2))
                .offset(x: 2, y: 2)
            )
            .padding(.top, 8)
            .padding(.bottom, 16)
          // Filter Section
          FilterSection()

          // Calendar Filter Info (when calendar filter is active)
          if viewModel.selectedFilter == .calendar,
            let selectedDate = viewModel.selectedCalendarDate
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
              }
              .onDelete { indexSet in
                Task {
                  await viewModel.deleteTodo(at: indexSet)
                }
              }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listRowSpacing(-12)
            .refreshable {
              await viewModel.fetchTodos()
            }
          }

          // Add Todo Button
          AddTodoButton(isAddingTodo: $isAddingTodo)
        }
      }
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

// Modern Calendar Filter Info Bar
private struct CalendarFilterInfo: View {
  let selectedDate: Date
  @EnvironmentObject private var viewModel: TodoViewModel

  var body: some View {
    HStack(spacing: 12) {
      // Calendar Icon
      Image(systemName: "calendar")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.blue)
        .frame(width: 32, height: 32)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(8)

      // Filter Text
      VStack(alignment: .leading, spacing: 2) {
        Text("Filtering by date")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.white.opacity(0.7))

        Text(formatDate(selectedDate))
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.white)
      }

      Spacer()

      // Clear Button
      Button(action: {
        viewModel.clearCalendarFilter()
      }) {
        HStack(spacing: 4) {
          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .bold))
          Text("Clear")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    )
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
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
    .background(Color.clear)
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

// Modern Filter Chip Component
private struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let count: Int
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Text(title)
          .font(.system(size: 14, weight: .semibold))

        if count > 0 {
          Text("\(count)")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(isSelected ? .white : .blue)
            .frame(minWidth: 20, minHeight: 20)
            .background(
              Circle()
                .fill(isSelected ? Color.white.opacity(0.3) : Color.blue.opacity(0.2))
            )
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(
            isSelected
              ? LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
              : LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(
                isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.3),
                lineWidth: 1
              )
          )
      )
      .foregroundColor(isSelected ? .white : .white.opacity(0.9))
      .scaleEffect(isSelected ? 1.05 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// Modern Todo Card Component
private struct TodoRowView: View {
  let todo: Todo
  @ObservedObject var viewModel: TodoViewModel
  let onEdit: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 4) {
        // Modern Checkbox
        Button(action: {
          Task {
            await viewModel.toggleTodoStatus(todo: todo)
          }
        }) {
          ZStack {
            Circle()
              .fill(todo.isCompleted ? Color.green : Color.gray.opacity(0.1))
              .frame(width: 24, height: 24)
              .overlay(
                Circle()
                  .stroke(todo.isCompleted ? Color.green : Color.gray.opacity(0.4), lineWidth: 2)
              )

            if todo.isCompleted {
              Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            }
          }
        }
        .buttonStyle(PlainButtonStyle())

        // Content Section
        VStack(alignment: .leading, spacing: 8) {
          // Todo Title
          HStack {
            Text(todo.title)
              .font(.system(size: 15))
              .strikethrough(todo.isCompleted)
              .foregroundColor(todo.isCompleted ? .secondary : .primary)
              .lineLimit(2)

            Spacer()

            // Activity Badge
            if todo.activityId != nil {
              HStack(spacing: 4) {
                Image(systemName: "dice.fill")
                  .font(.system(size: 9))
                Text("Activity")
                  .font(.system(size: 9, weight: .medium))
              }
              .foregroundColor(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.blue)
              .cornerRadius(10)
            }
          }

          // Due Date Info with modern styling
          if let dueDate = todo.dueDate {
            HStack(spacing: 6) {
              Image(systemName: "calendar")
                .font(.system(size: 11))
                .foregroundColor(getDueDateColor(dueDate))

              Text(formatDueDate(dueDate))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(getDueDateColor(dueDate))

              Spacer()

              // Priority indicator based on due date
              if getDueDateColor(dueDate) == .red {
                Text("OVERDUE")
                  .font(.system(size: 9, weight: .bold))
                  .foregroundColor(.white)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 3)
                  .background(Color.red)
                  .cornerRadius(8)
                  .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
              } else if getDueDateColor(dueDate) == .orange {
                Text("TODAY")
                  .font(.system(size: 9, weight: .bold))
                  .foregroundColor(.white)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 3)
                  .background(Color.orange)
                  .cornerRadius(8)
                  .shadow(color: Color.orange.opacity(0.3), radius: 2, x: 0, y: 1)
              }
            }
          }
        }

        .buttonStyle(PlainButtonStyle())
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(
          LinearGradient(
            gradient: Gradient(colors: [
              Color.white.opacity(todo.isCompleted ? 0.85 : 0.95),
              Color.white.opacity(todo.isCompleted ? 0.75 : 0.90),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
    .padding(.horizontal, 0)
    .padding(.vertical, 0)
    .contentShape(Rectangle())
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      // Modern Edit button
      Button {
        onEdit()
      } label: {
        VStack(spacing: 4) {
          Image(systemName: "pencil")
            .font(.system(size: 16, weight: .semibold))
          Text("Edit")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      }
      .tint(.clear)

      // Modern Delete button
      Button(role: .destructive) {
        if let index = viewModel.filteredTodos.firstIndex(where: { $0.id == todo.id }) {
          Task {
            await viewModel.deleteTodo(at: IndexSet([index]))
          }
        }
      } label: {
        VStack(spacing: 4) {
          Image(systemName: "trash")
            .font(.system(size: 16, weight: .semibold))
          Text("Delete")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          LinearGradient(
            gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      }
      .tint(.clear)
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
        .foregroundColor(.white.opacity(0.7))

      Text(getEmptyTitle())
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.white)

      Text(getEmptyMessage())
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.clear)
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
      HStack(spacing: 12) {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 24, height: 24)
          .background(Color.white.opacity(0.2))
          .cornerRadius(6)

        Text("Add Todo")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.white)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        LinearGradient(
          gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .cornerRadius(16)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.3), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .buttonStyle(PlainButtonStyle())
  }
}

// Preview
#Preview {
  TodoListView()
    .environmentObject(TodoViewModel())
}
