import SwiftUI

struct RandomActivityView: View {
  @StateObject private var viewModel = RandomActivityViewModel()
  @State private var editingCategory: Category?
  @State private var showEditSheet = false

  var body: some View {
    NavigationView {
      VStack(spacing: 16) {
        // Header Section
        headerSection

        if viewModel.isLoading {
          // Loading state
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Loading activities...")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxHeight: .infinity)
        } else if !viewModel.isDataReady {
          // No data state
          VStack(spacing: 16) {
            Image(systemName: "tray")
              .font(.title)
              .foregroundColor(.secondary)
            Text("No categories found")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("Please add some categories first")
              .font(.caption)
              .foregroundColor(.secondary)

            Button("Refresh") {
              Task {
                await viewModel.refreshData()
              }
            }
            .buttonStyle(.borderedProminent)
          }
          .frame(maxHeight: .infinity)
        } else {
          // Dynamic Slot Machines
          dynamicSlotMachinesSection

          Spacer()

          // Action Buttons
          actionButtonsSection
        }

        // Error message
        if let errorMessage = viewModel.errorMessage {
          Text("Error: \(errorMessage)")
            .font(.caption)
            .foregroundColor(.red)
            .padding()
        }

      }
      .padding(.horizontal, 20)
      .navigationTitle("Random Activity")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          historyButton
        }

        ToolbarItem(placement: .navigationBarLeading) {
          Button("Refresh") {
            Task {
              await viewModel.refreshData()
            }
          }
        }
      }
      .sheet(isPresented: $viewModel.showHistory) {
        historyView
      }
      .sheet(isPresented: $showEditSheet) {
        if let category = editingCategory {
          EditCategoryView(
            category: category,
            onDismiss: {
              showEditSheet = false
              editingCategory = nil
            },
            onSave: {
              Task {
                await viewModel.refreshData()
              }
              showEditSheet = false
              editingCategory = nil
            }
          )
        }
      }
    }
  }
}

// View Components
extension RandomActivityView {

  // Simplified header
  private var headerSection: some View {
    VStack(spacing: 8) {
      Text("Random Activity Generator")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.primary)

      if viewModel.isDataReady {
        if viewModel.totalCategories > 0 {
          Text("Tap each category to randomize (\(viewModel.totalCategories) categories)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        } else {
          Text("No categories available")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(.top, 8)
  }

  // Dynamic layout for slot machines based on actual categories
  private var dynamicSlotMachinesSection: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(viewModel.categories, id: \.id) { category in
          DynamicCompactSlotView(
            category: category,
            result: viewModel.getResult(for: category.id),
            isRolling: viewModel.isRolling(categoryId: category.id),
            availableActivities: viewModel.getActivities(for: category.id),
            categoryColor: getCategoryColor(for: category, index: getCategoryIndex(category)),
            onRoll: {
              viewModel.rollCategory(categoryId: category.id)
            },
            onEdit: {
              editingCategory = category
              showEditSheet = true
            }
          )
        }
      }
      .padding(.horizontal, 4)
    }
  }

  // Helper function to get color for category
  private func getCategoryColor(for category: Category, index: Int) -> Color {
    let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .cyan, .indigo]
    return colors[index % colors.count]
  }

  // Helper function to get category index for color
  private func getCategoryIndex(_ category: Category) -> Int {
    return viewModel.categories.firstIndex { $0.id == category.id } ?? 0
  }

  // Simplified action buttons
  private var actionButtonsSection: some View {
    VStack(spacing: 12) {

      // Roll all button - more minimal design
      Button(action: {
        viewModel.rollAllSlots()
      }) {
        HStack(spacing: 8) {
          Image(systemName: "shuffle")
            .font(.body)

          Text("Randomize All (\(viewModel.totalCategories))")
            .font(.body)
            .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color.accentColor)
        .cornerRadius(8)
      }
      .disabled(
        viewModel.isAnySlotRolling || !viewModel.isDataReady || viewModel.totalCategories == 0
      )
      .opacity(
        viewModel.isAnySlotRolling || !viewModel.isDataReady || viewModel.totalCategories == 0
          ? 0.6 : 1.0)

      // Reset button
      if viewModel.hasAnyResult {
        Button(action: {
          viewModel.resetAllSlots()
        }) {
          HStack(spacing: 6) {
            Image(systemName: "arrow.clockwise")
              .font(.caption)
            Text("Reset All")
              .font(.caption)
          }
          .foregroundColor(.secondary)
        }
      }

      // Completion indicator
      if viewModel.allSlotsComplete {
        HStack(spacing: 8) {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text(
            "All activities selected (\(viewModel.completedSlotsCount)/\(viewModel.totalCategories))"
          )
          .font(.subheadline)
          .foregroundColor(.green)
        }
        .padding(.vertical, 8)
        .transition(.opacity)
      }
    }
  }

  // Minimal history button
  private var historyButton: some View {
    Button(action: {
      viewModel.toggleHistory()
    }) {
      Image(systemName: "clock")
        .foregroundColor(.accentColor)
    }
  }

  // History sheet view
  private var historyView: some View {
    NavigationView {
      List {
        if viewModel.hasHistory {
          ForEach(Array(viewModel.activityHistory.enumerated()), id: \.offset) { index, activity in
            DynamicHistoryRowView(activity: activity, index: index + 1)
          }
        } else {
          VStack(spacing: 12) {
            Image(systemName: "clock")
              .font(.title2)
              .foregroundColor(.secondary)
            Text("No history yet")
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding()
        }
      }
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") {
            viewModel.showHistory = false
          }
        }

        if viewModel.hasHistory {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Clear") {
              viewModel.clearHistory()
            }
            .foregroundColor(.red)
          }
        }
      }
    }
  }
}

// Dynamic Compact Slot Machine Component
struct DynamicCompactSlotView: View {
  let category: Category
  let result: Activity?
  let isRolling: Bool
  let availableActivities: [Activity]
  let categoryColor: Color
  let onRoll: () -> Void
  let onEdit: () -> Void

  @State private var currentSpinIndex = 0
  @State private var spinTimer: Timer?
  @State private var allEmojis: [String] = []

  // Get default emoji for category based on icon or name
  private var defaultEmoji: String {
    if let iconName = category.iconName, !iconName.isEmpty {
      return iconName
    }

    // Fallback based on category name patterns
    let name = category.name.lowercased()
    if name.contains("đi") || name.contains("go") || name.contains("place") {
      return "📍"
    } else if name.contains("chơi") || name.contains("play") || name.contains("activity") {
      return "🎮"
    } else if name.contains("ăn") || name.contains("eat") || name.contains("food") {
      return "🍜"
    } else {
      return "🎲"
    }
  }

  // Check if category has activities
  private var hasActivities: Bool {
    !availableActivities.isEmpty
  }

  var body: some View {
    VStack(spacing: 0) {
      // Main slot machine button
      Button(action: {
        if !isRolling && hasActivities {
          onRoll()
        }
      }) {
        // Unified horizontal layout for all states
        HStack(spacing: 12) {

          // Left: Image/Emoji display (compact slot or result)
          if let result = result, !isRolling {
            // Completed state - show result image or icon
            ActivityImageView(
              activity: result,
              size: 50,
              cornerRadius: 10,
              defaultIcon: defaultEmoji,
              backgroundColor: categoryColor.opacity(0.1)
            )
          } else {
            // Empty/Rolling state - show slot display with same size as result
            ZStack {
              RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.8))
                .frame(width: 50, height: 50)
                .overlay(
                  RoundedRectangle(cornerRadius: 10)
                    .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )

              // Content
              if isRolling {
                // Spinning state
                Text(allEmojis.isEmpty ? "🎲" : allEmojis[currentSpinIndex])
                  .font(.title2)
                  .foregroundColor(.white)
                  .blur(radius: 0.5)
              } else if !hasActivities {
                // No data state
                Image(systemName: "plus")
                  .font(.title3)
                  .foregroundColor(.secondary)
              } else {
                // Empty state
                Image(systemName: "hand.tap")
                  .font(.title3)
                  .foregroundColor(categoryColor.opacity(0.6))
              }
            }
          }

          // Center: Text content
          VStack(alignment: .leading, spacing: 2) {
            Text(category.name)
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.secondary)

            if let result = result, !isRolling {
              Text(result.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            } else if isRolling {
              Text("Randomizing...")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(categoryColor)
            } else if !hasActivities {
              Text("No activities added")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            } else {
              Text("Tap to randomize (\(availableActivities.count))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            }
          }

          Spacer()

          // Right: Status indicator and Edit button
          HStack(spacing: 8) {
            // Edit button
            Button(action: onEdit) {
              Image(systemName: "pencil.circle.fill")
                .font(.title3)
                .foregroundColor(categoryColor)
            }
            .buttonStyle(PlainButtonStyle())

            // Status indicator
            if !isRolling && result != nil {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            } else if isRolling {
              ProgressView()
                .scaleEffect(0.8)
                .tint(categoryColor)
            } else if !hasActivities {
              Image(systemName: "exclamationmark.triangle")
                .font(.title3)
                .foregroundColor(.orange)
            } else {
              Image(systemName: "hand.tap")
                .font(.title3)
                .foregroundColor(categoryColor.opacity(0.6))
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray6))
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(
                  isRolling ? categoryColor : Color.clear,
                  lineWidth: isRolling ? 2 : 0
                )
                .animation(.easeInOut(duration: 0.3), value: isRolling)
            )
        )
      }
      .buttonStyle(PlainButtonStyle())
      .disabled(!hasActivities)
    }
    .onAppear {
      setupEmojis()
    }
    .onChange(of: isRolling) { _, newValue in
      if newValue {
        startSpinning()
      } else {
        stopSpinning()
      }
    }
  }

  private func setupEmojis() {
    // Use activity icons/emojis or fallback to default emojis
    allEmojis = availableActivities.compactMap { $0.iconName }

    if allEmojis.isEmpty {
      allEmojis = [defaultEmoji]
    }

    let extraSymbols = ["🎲", "⚡", "✨", "🔄"]
    allEmojis.append(contentsOf: extraSymbols)
    allEmojis.shuffle()
  }

  private func startSpinning() {
    currentSpinIndex = 0

    spinTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
      withAnimation(.easeInOut(duration: 0.08)) {
        currentSpinIndex = (currentSpinIndex + 1) % allEmojis.count
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      spinTimer?.invalidate()

      spinTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
        withAnimation(.easeInOut(duration: 0.2)) {
          currentSpinIndex = (currentSpinIndex + 1) % allEmojis.count
        }
      }
    }
  }

  private func stopSpinning() {
    spinTimer?.invalidate()
    spinTimer = nil
  }
}

// Dynamic History Row
struct DynamicHistoryRowView: View {
  let activity: DatabaseRandomActivity
  let index: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("#\(index)")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundColor(.accentColor)

        Spacer()

        Text(formatDate(activity.generatedAt))
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      // Dynamic tags based on actual results
      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
        ], spacing: 6
      ) {
        ForEach(activity.formattedResults, id: \.categoryName) { result in
          ActivityTag(title: "\(result.categoryName): \(result.activityName)", color: .accentColor)
        }
      }
    }
    .padding(.vertical, 2)
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

// Activity Tag Component (reused)
struct ActivityTag: View {
  let title: String
  let color: Color

  var body: some View {
    Text(title)
      .font(.caption2)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(color.opacity(0.1))
      .foregroundColor(color)
      .cornerRadius(4)
      .lineLimit(1)
  }
}

// Preview
#Preview {
  RandomActivityView()
}
