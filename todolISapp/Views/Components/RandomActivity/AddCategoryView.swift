import Supabase
import SwiftUI

/// Component for adding new categories
/// Handles category creation with name input only
struct AddCategoryView: View {
  @Environment(\.dismiss) private var dismiss

  // Callbacks
  let onDismiss: () -> Void
  let onSave: (Category) -> Void

  // Form state
  @State private var categoryName: String = ""
  @State private var isLoading: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationView {
      ZStack {
        // Gradient background
        LinearGradient(
          gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.1)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)

        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Text("Create New Category")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.white)

            Text("Enter a name for your category")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))
          }
          .padding(.top)

          // Form content
          VStack(spacing: 20) {
            // Name input
            nameInputSection

            // Error message
            if let errorMessage = errorMessage {
              Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal)
            }
          }
          .padding(.horizontal, 20)

          Spacer()

          // Loading indicator
          if isLoading {
            ProgressView()
              .scaleEffect(1.2)
              .tint(.white)
              .padding()
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .toolbarBackground(.clear, for: .navigationBar)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button("Cancel") {
            print("🚪 AddCategoryView Cancel button tapped")
            dismiss()
            onDismiss()
          }
          .foregroundColor(.white)
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
          if isLoading {
            ProgressView()
              .scaleEffect(0.8)
              .tint(.white)
          } else {
            Button("Create") {
              print("✅ AddCategoryView Create button tapped")
              Task {
                await createCategory()
              }
            }
            .foregroundColor(.white)
            .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
        }
      }
      .onAppear {
        print("📋 AddCategoryView appeared")
      }
      .onDisappear {
        print("📋 AddCategoryView disappeared")
      }
    }
  }
}

// MARK: - View Components
extension AddCategoryView {

  private var nameInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Category Name")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white)

      TextField("Enter category name", text: $categoryName)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 16)
    .background(Color.white.opacity(0.1))
    .cornerRadius(12)
  }
}

// MARK: - Private Methods
extension AddCategoryView {

  private func createCategory() async {
    let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

    // Validation
    guard !trimmedName.isEmpty else {
      errorMessage = "Category name cannot be empty"
      return
    }

    guard trimmedName.count >= 2 else {
      errorMessage = "Category name must be at least 2 characters"
      return
    }

    guard trimmedName.count <= 50 else {
      errorMessage = "Category name must be less than 50 characters"
      return
    }

    // Clear any previous errors
    errorMessage = nil
    isLoading = true

    do {
      // Get current user
      let session = try await SupabaseManager.shared.client.auth.session
      let user = session.user

      print("🔄 Creating category: \(trimmedName) for user: \(user.id)")

      // Create category object
      let newCategory = NewCategoryRequest(
        name: trimmedName,
        user_id: user.id,
        icon_name: "📝"  // Default icon
      )

      // Insert into Supabase and get the created category back
      let createdCategories: [Category] = try await SupabaseManager.shared.client
        .from("categories")
        .insert(newCategory)
        .select()
        .execute()
        .value

      guard let createdCategory = createdCategories.first else {
        throw NSError(
          domain: "Database", code: 500,
          userInfo: [NSLocalizedDescriptionKey: "Failed to create category"])
      }

      print(
        "✅ Category created successfully: \(createdCategory.name) with ID: \(createdCategory.id)")

      // Call success callback
      await MainActor.run {
        onSave(createdCategory)
      }

    } catch {
      print("❌ Error creating category: \(error)")
      await MainActor.run {
        errorMessage = "Failed to create category: \(error.localizedDescription)"
        isLoading = false
      }
    }
  }
}

// MARK: - Preview
#Preview {
  AddCategoryView(
    onDismiss: {
      print("Add category dismissed")
    },
    onSave: { category in
      print("Category saved: \(category.name)")
    }
  )
}
