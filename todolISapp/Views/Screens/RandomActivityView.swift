import SwiftUI

// MARK: - Sheet Types
enum SheetType: Identifiable {
  case editCategory(Category)
  case addActivity(Category)
  case addCategory

  var id: String {
    switch self {
    case .editCategory(let category):
      return "edit_\(category.id)"
    case .addActivity(let category):
      return "activity_\(category.id)"
    case .addCategory:
      return "add_category"
    }
  }
}

struct RandomActivityView: View {
  @StateObject private var viewModel = RandomActivityViewModel()
  @State private var activeSheet: SheetType?
  @State private var newlyCreatedCategory: Category?  // Để track category vừa tạo
  @EnvironmentObject private var todoViewModel: TodoViewModel

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

        VStack(spacing: 16) {
          // Header Section
          headerSection

          if viewModel.isLoading {
            // Loading state
            VStack(spacing: 16) {
              ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
              Text("Loading activities...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxHeight: .infinity)
          } else if !viewModel.isDataReady {
            // No data state
            VStack(spacing: 16) {
              Image(systemName: "tray")
                .font(.title)
                .foregroundColor(.white.opacity(0.7))
              Text("No categories found")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
              Text("Please add some categories first")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

                .buttonStyle(.borderedProminent)
            }
            .frame(maxHeight: .infinity)
          } else {
            // Dynamic Slot Machines
            dynamicSlotMachinesSection

            Spacer()

            // Bottom buttons
            VStack(spacing: 12) {

              // Refresh Button
              RefreshButton {
                Task {
                  await viewModel.refreshData()
                }
              }
            }
          }

          // Error message
          if let errorMessage = viewModel.errorMessage {
            Text("Error: \(errorMessage)")
              .font(.caption)
              .foregroundColor(.red.opacity(0.8))
              .padding()
          }
        }
        .padding(.horizontal, 20)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(action: {
            print("🔍 Add Category button tapped from toolbar")
            activeSheet = .addCategory
            print("📱 activeSheet set to: \(String(describing: activeSheet))")
          }) {
            Image(systemName: "plus")
              .foregroundColor(.white)
          }
        }
      }
      .sheet(item: $activeSheet) { sheetType in
        switch sheetType {
        case .editCategory(let category):
          EditCategoryView(
            category: category,
            onDismiss: {
              activeSheet = nil
            },
            onSave: {
              Task {
                await viewModel.refreshData()
              }
              activeSheet = nil
            }
          )

        case .addActivity(let category):
          AddActivityView(
            categoryId: category.id,
            onDismiss: {
              activeSheet = nil
            },
            onSave: { newActivity in
              print("✅ New activity added: \(newActivity.name)")
              Task {
                await viewModel.refreshData()
              }
              activeSheet = nil
            }
          )

        case .addCategory:
          AddCategoryView(
            onDismiss: {
              print("🚪 AddCategoryView dismissed")
              activeSheet = nil
            },
            onSave: { newCategory in
              print("✅ New category created: \(newCategory.name)")

              // Store category name để tìm sau khi refresh
              let categoryName = newCategory.name

              // Refresh data để load category mới
              Task {
                await viewModel.refreshData()

                // Sau khi refresh xong, tìm category theo name và auto-edit
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  if let foundCategory = viewModel.categories.first(where: {
                    $0.name == categoryName
                  }
                  ) {
                    print("🔄 Auto-opening edit for new category: \(foundCategory.name)")
                    activeSheet = .editCategory(foundCategory)
                  } else {
                    print("⚠️ Could not find newly created category: \(categoryName)")
                  }
                }
              }

              activeSheet = nil
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
      Text("Don't know what to do?")
        .font(.system(size: 32, weight: .bold))
        .foregroundColor(.white)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        .overlay(
          Text("Don't know what to do?")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Color.blue.opacity(0.2))
            .offset(x: 2, y: 2)
        )
        .padding(.top, 8)
        .padding(.bottom, 16)

      if viewModel.isDataReady {
        if viewModel.totalCategories > 0 {
          Text("Tap to randomize (\(viewModel.totalCategories) categories)")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
        } else {
          Text("No categories available")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
        }
      }
    }
    .padding(.top, 8)
  }

  // Dynamic layout for slot machines based on actual categories
  private var dynamicSlotMachinesSection: some View {
    List {
      ForEach(viewModel.categories, id: \.id) { category in
        DynamicCompactSlotView(
          category: category,
          result: viewModel.getResult(for: category.id),
          isRolling: viewModel.isRolling(categoryId: category.id),
          availableActivities: viewModel.getActivities(for: category.id),
          categoryColor: getCategoryColor(for: category, index: getCategoryIndex(category)),
          onRoll: {
            // Only allow rolling if category has enough activities
            if viewModel.hasEnoughActivities(for: category.id) {
              viewModel.rollCategory(categoryId: category.id) { activityResult, categoryResult in
                // When rolling is done, this action will be performed
                print("Adding to todo: \(categoryResult.name): \(activityResult.name)")
                Task {
                  await todoViewModel.addTodoFromActivity(activity: activityResult)
                }
              }
            }
          },
          onEdit: {
            // Debug log để track vấn đề
            print("🔍 Edit tapped for category: \(category.name)")
            activeSheet = .editCategory(category)
            print("📱 activeSheet set to: \(String(describing: activeSheet))")
          },
          onDelete: {
            Task {
              await viewModel.deleteCategory(categoryId: category.id)
            }
          }
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .listRowSpacing(0)
    .refreshable {
      Task {
        await viewModel.refreshData()
      }
    }
  }

  // Helper function to get color for category - now returns consistent color
  private func getCategoryColor(for category: Category, index: Int) -> Color {
    return .blue.opacity(0.8)
  }

  // Helper function to get category index for color
  private func getCategoryIndex(_ category: Category) -> Int {
    return viewModel.categories.firstIndex { $0.id == category.id } ?? 0
  }
}

// Add Category Button Component
private struct AddCategoryButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 24, height: 24)
          .background(Color.white.opacity(0.2))
          .cornerRadius(6)

        Text("Add Category")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.white)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        LinearGradient(
          gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
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

// Refresh Button Component
private struct RefreshButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 24, height: 24)
          .background(Color.white.opacity(0.2))
          .cornerRadius(6)

        Text("Refresh Activities")
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

// Dynamic Compact Slot Machine Component
struct DynamicCompactSlotView: View {
  let category: Category
  let result: Activity?
  let isRolling: Bool
  let availableActivities: [Activity]
  let categoryColor: Color  // Keep parameter for compatibility but use consistent color
  let onRoll: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  @State private var currentSpinIndex = 0
  @State private var spinTimer: Timer?
  @State private var allEmojis: [String] = []

  // Consistent color for all categories
  private var consistentColor: Color {
    return .white.opacity(0.8)
  }

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
    // Main container with separate clickable areas
    HStack(spacing: 12) {
      // Left: Image/Emoji display (compact slot or result) - Clickable for roll
      Group {
        if let result = result, !isRolling {
          // Completed state - show result image or icon
          ActivityImageView(
            activity: result,
            size: 50,
            cornerRadius: 10,
            defaultIcon: defaultEmoji,
            backgroundColor: consistentColor.opacity(0.1)
          )
        } else {
          // Empty/Rolling state - show slot display with same size as result
          ZStack {
            RoundedRectangle(cornerRadius: 10)
              .fill(Color.black.opacity(0.8))
              .frame(width: 50, height: 50)
              .overlay(
                RoundedRectangle(cornerRadius: 10)
                  .stroke(consistentColor.opacity(0.3), lineWidth: 1)
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
                .foregroundColor(consistentColor.opacity(0.6))
            }
          }
        }
      }
      .onTapGesture {
        if !isRolling && hasActivities && availableActivities.count >= 2 {
          onRoll()
        }
      }

      // Center: Text content - Clickable for roll
      Group {
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
              .foregroundColor(consistentColor)
          } else if !hasActivities {
            Text("No activities added")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.secondary)
          } else if availableActivities.count < 2 {
            Text("Need 2+ activities (\(availableActivities.count)/2)")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.orange)
          } else {
            Text("Tap to randomize (\(availableActivities.count))")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.secondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .onTapGesture {
        if !isRolling && hasActivities && availableActivities.count >= 2 {
          onRoll()
        }
      }

      // Right: Status indicator
      HStack(spacing: 8) {
        // Status indicator
        if !isRolling && result != nil {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
            .font(.title3)
        } else if isRolling {
          ProgressView()
            .scaleEffect(0.8)
            .tint(consistentColor)
        } else if !hasActivities {
          Image(systemName: "exclamationmark.triangle")
            .font(.title3)
            .foregroundColor(.orange)
        } else if availableActivities.count < 2 {
          Image(systemName: "exclamationmark.triangle")
            .font(.title3)
            .foregroundColor(.orange)
        } else {
          Image(systemName: "hand.tap")
            .font(.title3)
            .foregroundColor(consistentColor.opacity(0.6))
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemGray6))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(
              isRolling ? consistentColor : Color.clear,
              lineWidth: isRolling ? 2 : 0
            )
            .animation(.easeInOut(duration: 0.3), value: isRolling)
        )
    )
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
        onDelete()
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
    .onAppear {
      setupEmojis()
    }
    .onChange(of: isRolling) { newValue in
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

// Preview
#Preview {
  RandomActivityView()
}
