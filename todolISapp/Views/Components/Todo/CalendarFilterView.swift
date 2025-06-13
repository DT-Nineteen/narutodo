import SwiftUI

/// Calendar picker component for filtering todos by specific date
struct CalendarFilterView: View {
  @EnvironmentObject private var viewModel: TodoViewModel
  @Binding var isPresented: Bool
  @State private var selectedDate = Date()

  var body: some View {
    NavigationView {
      VStack(spacing: 16) {
        // Header with explanation
        VStack(spacing: 8) {
          Text("Filter by Date")
            .font(.title2)
            .fontWeight(.bold)

          Text("Select a date to view todos due on that day")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.top)

        // Calendar picker
        DatePicker(
          "Select Date",
          selection: $selectedDate,
          displayedComponents: [.date]
        )
        .datePickerStyle(GraphicalDatePickerStyle())
        .padding(.horizontal)

        // Quick date buttons
        quickDateButtons

        Spacer()

        // Action buttons
        actionButtons
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            isPresented = false
          }
        }
      }
    }
    .onAppear {
      // Set initial date to selected calendar date or today
      selectedDate = viewModel.selectedCalendarDate ?? Date()
      print("[DEBUG] CalendarFilterView appeared with date: \(selectedDate)")
    }
  }

  // Quick date selection buttons
  private var quickDateButtons: some View {
    VStack(spacing: 12) {
      Text("Quick Select")
        .font(.headline)
        .padding(.top)

      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible()),
        ], spacing: 8
      ) {
        QuickDateButton(title: "Today", date: Date()) {
          selectedDate = Date()
        }

        QuickDateButton(
          title: "Tomorrow",
          date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        ) {
          selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }

        QuickDateButton(
          title: "Next Week",
          date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        ) {
          selectedDate =
            Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        }
      }
    }
    .padding(.horizontal)
  }

  // Action buttons at bottom
  private var actionButtons: some View {
    VStack(spacing: 12) {
      // Apply filter button
      Button(action: {
        viewModel.selectCalendarDate(selectedDate)
        isPresented = false
      }) {
        HStack {
          Image(systemName: "calendar.circle.fill")
          Text("Filter by \(formatDate(selectedDate))")
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.accentColor)
        .cornerRadius(10)
      }

      // Clear filter button
      if viewModel.selectedCalendarDate != nil {
        Button(action: {
          viewModel.clearCalendarFilter()
          isPresented = false
        }) {
          HStack {
            Image(systemName: "xmark.circle")
            Text("Clear Date Filter")
          }
          .font(.subheadline)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(Color(.systemGray6))
          .cornerRadius(8)
        }
      }
    }
    .padding(.horizontal)
    .padding(.bottom, 8)
  }

  // Format date for display
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
}

// Quick date selection button component
private struct QuickDateButton: View {
  let title: String
  let date: Date
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Text(title)
          .font(.caption)
          .fontWeight(.medium)

        Text(formatShortDate(date))
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(Color(.systemGray6))
      .cornerRadius(8)
    }
    .foregroundColor(.primary)
  }

  private func formatShortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    return formatter.string(from: date)
  }
}

// MARK: - Preview
#Preview {
  CalendarFilterView(isPresented: .constant(true))
    .environmentObject(TodoViewModel())
}
