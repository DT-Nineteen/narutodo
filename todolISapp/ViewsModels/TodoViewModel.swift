import Foundation
import Supabase

// Filter options for todos
enum TodoFilter: String, CaseIterable {
  case all = "All"
  case today = "Today"
  case tomorrow = "Tomorrow"
  case overdue = "Overdue"
  case thisWeek = "This Week"
  case calendar = "Calendar"  // New calendar filter

  var displayName: String {
    return self.rawValue
  }
}

@MainActor
class TodoViewModel: ObservableObject {
  @Published var todos: [Todo] = []
  @Published var errorMessage: String?
  @Published var isLoading = false
  @Published var selectedFilter: TodoFilter = .all
  @Published var selectedCalendarDate: Date? = nil  // New: selected date from calendar
  @Published var showCalendarPicker = false  // New: show/hide calendar picker
  @Published var showErrorAlert = false  // New: show error as alert

  // Computed property for filtered todos
  var filteredTodos: [Todo] {
    let allTodos = todos
    print("[DEBUG] Filtering \(allTodos.count) todos with filter: \(selectedFilter)")

    switch selectedFilter {
    case .all:
      return allTodos
    case .today:
      let filtered = allTodos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
      }
      print("[DEBUG] Today filter: \(filtered.count) todos")
      return filtered
    case .tomorrow:
      let filtered = allTodos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
      }
      print("[DEBUG] Tomorrow filter: \(filtered.count) todos")
      return filtered
    case .overdue:
      let filtered = allTodos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date()) && !todo.isCompleted
      }
      print("[DEBUG] Overdue filter: \(filtered.count) todos")
      return filtered
    case .thisWeek:
      let filtered = allTodos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
          return false
        }
        return weekInterval.contains(dueDate)
      }
      print("[DEBUG] This week filter: \(filtered.count) todos")
      return filtered
    case .calendar:
      // New: Filter by selected calendar date
      guard let selectedDate = selectedCalendarDate else {
        print("[DEBUG] Calendar filter: no date selected, returning all todos")
        return allTodos
      }
      let filtered = allTodos.filter { todo in
        guard let dueDate = todo.dueDate else { return false }
        return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
      }
      print("[DEBUG] Calendar filter for \(selectedDate): \(filtered.count) todos")
      return filtered
    }
  }

  // READ TODO LIST
  func fetchTodos() async {
    print("[DEBUG] Fetching todos...")
    do {
      let session = try await SupabaseManager.shared.client.auth.session
      let currentUserId = session.user.id
      // Get all todos from Supabase for current user
      let fetchedTodos: [Todo] = try await SupabaseManager.shared.client
        .from("todos")
        .select()
        .eq("user_id", value: currentUserId)
        .order("created_at", ascending: true)
        .execute()
        .value
      self.todos = fetchedTodos
      print("[DEBUG] Successfully fetched \(fetchedTodos.count) todos")

      // Clear any previous errors
      self.errorMessage = nil
    } catch {
      print("[DEBUG] Error fetching todos: \(error)")
      self.errorMessage = "Failed to load todos. Please try again."
      self.showErrorAlert = true
    }
  }

  // UPDATE TODO STATUS
  func toggleTodoStatus(todo: Todo) async {
    print("[DEBUG] Toggling todo status: \(todo.id)")
    let session = try? await SupabaseManager.shared.client.auth.session
    let currentUserId = session?.user.id
    guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
      print("[DEBUG] Todo not found in local array")
      return
    }

    // Store original state for rollback
    let originalState = todos[index].isCompleted

    // Update the local array optimistically
    self.todos[index].isCompleted.toggle()

    do {
      var updatedTodo = todo
      updatedTodo.isCompleted = !originalState

      try await SupabaseManager.shared.client
        .from("todos")
        .update(updatedTodo)
        .eq("id", value: todo.id)
        .eq("user_id", value: currentUserId)
        .execute()
      print("[DEBUG] Successfully toggled todo status")
    } catch {
      // Rollback on error
      self.todos[index].isCompleted = originalState
      print("[DEBUG] Error updating todo: \(error)")
      self.errorMessage = "Failed to update task. Please try again."
      self.showErrorAlert = true
    }
  }

  // UPDATE TODO (Edit functionality)
  func updateTodo(todo: Todo, newTitle: String, newDueDate: Date) async {
    print("[DEBUG] Updating todo: \(todo.id) with title: \(newTitle)")
    let session = try? await SupabaseManager.shared.client.auth.session
    let currentUserId = session?.user.id

    guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
      print("[DEBUG] Todo not found for update")
      return
    }

    // Store original values for rollback
    let originalTitle = todos[index].title
    let originalDueDate = todos[index].dueDate

    // Update local array optimistically
    self.todos[index].title = newTitle
    self.todos[index].dueDate = newDueDate

    do {
      var updatedTodo = todo
      updatedTodo.title = newTitle
      updatedTodo.dueDate = newDueDate

      try await SupabaseManager.shared.client
        .from("todos")
        .update(updatedTodo)
        .eq("id", value: todo.id)
        .eq("user_id", value: currentUserId)
        .execute()
      print("[DEBUG] Successfully updated todo")
    } catch {
      // Rollback on error
      self.todos[index].title = originalTitle
      self.todos[index].dueDate = originalDueDate
      print("[DEBUG] Error updating todo: \(error)")
      self.errorMessage = "Failed to update todo. Please try again."
      self.showErrorAlert = true
    }
  }

  // DELETE
  func deleteTodo(at offsets: IndexSet) async {
    print("[DEBUG] Deleting todos at offsets: \(offsets)")
    let session = try? await SupabaseManager.shared.client.auth.session
    let currentUserId = session?.user.id

    // Use filteredTodos for deletion since that's what user sees
    let todosToDelete = offsets.map { self.filteredTodos[$0] }

    // Remove from filtered view immediately
    var indicesToRemove: [Int] = []
    for todo in todosToDelete {
      if let index = self.todos.firstIndex(where: { $0.id == todo.id }) {
        indicesToRemove.append(index)
      }
    }

    // Store deleted todos for potential rollback
    let deletedTodos = indicesToRemove.map { todos[$0] }

    // Remove from local array optimistically
    for index in indicesToRemove.sorted(by: >) {
      self.todos.remove(at: index)
    }

    Task {
      for todo in todosToDelete {
        do {
          try await SupabaseManager.shared.client
            .from("todos")
            .delete()
            .eq("id", value: todo.id)
            .eq("user_id", value: currentUserId)
            .execute()
          print("✅ Successfully deleted todo \(todo.id) from server.")

        } catch {
          print("❌ Error deleting todo \(todo.id): \(error.localizedDescription)")
          // Rollback: re-add deleted todos
          for (index, deletedTodo) in zip(indicesToRemove, deletedTodos) {
            self.todos.insert(deletedTodo, at: min(index, self.todos.count))
          }
          self.errorMessage = "Failed to delete task. Please try again."
          self.showErrorAlert = true
          break
        }
      }
    }
  }

  // CREATE TODO FROM ACTIVITY
  private struct NewTodo: Encodable {
    let title: String
    let activity_id: UUID?
    let user_id: UUID
    let is_completed: Bool
    let due_date: String?  // Change to String for proper date formatting

    init(title: String, activity_id: UUID?, user_id: UUID, is_completed: Bool, due_date: Date?) {
      self.title = title
      self.activity_id = activity_id
      self.user_id = user_id
      self.is_completed = is_completed

      // Format date for Supabase (date only format)
      if let dueDate = due_date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.due_date = formatter.string(from: dueDate)
        print("[DEBUG] Formatting due_date for Supabase: \(dueDate) -> \(self.due_date ?? "nil")")
      } else {
        self.due_date = nil
      }
    }
  }

  func addTodoFromActivity(activity: Activity, category: Category? = nil) async {
    print("[DEBUG] Adding todo from activity: \(activity.name)")
    let session = try? await SupabaseManager.shared.client.auth.session
    let currentUserId = session?.user.id
    guard let userId = currentUserId else {
      self.errorMessage = "Please log in to add todos."
      self.showErrorAlert = true
      return
    }

    // Set default due date to today for activity-generated todos
    let defaultDueDate = Date()
    print("[DEBUG] Setting default due date for activity todo: \(defaultDueDate)")

    // Format title as "category: activity" if category is provided
    let todoTitle =
      if let category = category {
        "\(category.name): \(activity.name)"
      } else {
        activity.name
      }
    print("[DEBUG] Todo title format: \(todoTitle)")

    let newTodo = NewTodo(
      title: todoTitle,
      activity_id: activity.id,
      user_id: userId,
      is_completed: false,
      due_date: defaultDueDate  // Set due date to today by default
    )

    do {
      let insertedTodo: Todo = try await SupabaseManager.shared.client
        .from("todos")
        .insert(newTodo, returning: .representation)
        .single()
        .execute()
        .value

      self.todos.insert(insertedTodo, at: 0)
      print("[DEBUG] Successfully added todo from activity")
    } catch {
      self.errorMessage = "Failed to add task from activity. Please try again."
      self.showErrorAlert = true
      print("[DEBUG] Error adding todo from activity: \(error)")
    }
  }

  // CREATE TODO WITH DUE DATE
  func addTodo(title: String, dueDate: Date? = nil) async {
    print("[DEBUG] Adding new todo: \(title)")
    let session = try? await SupabaseManager.shared.client.auth.session
    let currentUserId = session?.user.id
    guard let userId = currentUserId else {
      self.errorMessage = "Please log in to add todos."
      self.showErrorAlert = true
      return
    }

    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else {
      self.errorMessage = "Todo title cannot be empty."
      self.showErrorAlert = true
      return
    }

    let newTodo = NewTodo(
      title: trimmedTitle,
      activity_id: nil,
      user_id: userId,
      is_completed: false,
      due_date: dueDate
    )

    do {
      let insertedTodo: Todo = try await SupabaseManager.shared.client
        .from("todos")
        .insert(newTodo, returning: .representation)
        .single()
        .execute()
        .value

      self.todos.insert(insertedTodo, at: 0)
      print("[DEBUG] Successfully added new todo")
    } catch {
      self.errorMessage = "Failed to add todo. Please try again."
      self.showErrorAlert = true
      print("[DEBUG] Error adding todo: \(error)")
    }
  }

  // FILTER FUNCTIONS
  func setFilter(_ filter: TodoFilter) {
    print("[DEBUG] Setting filter to: \(filter.displayName)")
    selectedFilter = filter

    // Show calendar picker when calendar filter is selected
    if filter == .calendar {
      showCalendarPicker = true
      // Set default to today if no date selected
      if selectedCalendarDate == nil {
        selectedCalendarDate = Date()
      }
    }
  }

  // NEW: Calendar filter functions
  func selectCalendarDate(_ date: Date) {
    print("[DEBUG] Selected calendar date: \(date)")
    selectedCalendarDate = date
    selectedFilter = .calendar
    showCalendarPicker = false
  }

  func clearCalendarFilter() {
    print("[DEBUG] Clearing calendar filter")
    selectedCalendarDate = nil
    selectedFilter = .all
    showCalendarPicker = false
  }

  // Clear error message
  func clearError() {
    errorMessage = nil
    showErrorAlert = false
  }
}
