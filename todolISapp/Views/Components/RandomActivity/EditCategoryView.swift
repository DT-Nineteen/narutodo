import PhotosUI
import SwiftUI

struct EditCategoryView: View {
  let category: Category
  let onDismiss: () -> Void
  let onSave: () -> Void

  @StateObject private var viewModel = EditCategoryViewModel()
  @State private var editingActivityId: UUID?
  @State private var showingAddActivity = false
  @State private var showingDeleteCategoryAlert = false
  @State private var showingDeleteActivityAlert = false
  @State private var activityToDelete: Activity?

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

        ScrollView {
          VStack(spacing: 20) {
            // MARK: - Category Section
            categorySection

            // MARK: - Activities Section
            activitiesSection

            // MARK: - Danger Zone
            dangerZoneSection
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
        }
      }

      .navigationBarTitleDisplayMode(.inline)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .toolbarBackground(.clear, for: .navigationBar)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button("Cancel") {
            onDismiss()
          }
          .foregroundColor(.white)
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button("Save") {
            Task {
              await viewModel.saveCategory()
              onSave()
            }
          }
          .foregroundColor(.white)
          .disabled(
            viewModel.isLoading
              || viewModel.categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              || viewModel.activities.count < 2)
        }
      }
      .alert("Delete Category", isPresented: $showingDeleteCategoryAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          Task {
            await viewModel.deleteCategory()
            onSave()
          }
        }
      } message: {
        Text(
          "Are you sure you want to delete this category and all its activities? This action cannot be undone."
        )
      }
      .alert("Delete Activity", isPresented: $showingDeleteActivityAlert) {
        Button("Cancel", role: .cancel) {
          activityToDelete = nil
        }
        Button("Delete", role: .destructive) {
          if let activity = activityToDelete {
            Task {
              await viewModel.deleteActivity(activity)
              activityToDelete = nil
            }
          }
        }
      } message: {
        Text("Are you sure you want to delete this activity?")
      }
      .sheet(isPresented: $showingAddActivity) {
        AddActivityView(
          categoryId: category.id,
          onDismiss: {
            showingAddActivity = false
          },
          onSave: { newActivity in
            viewModel.addActivity(newActivity)
            showingAddActivity = false
          }
        )
      }
      .sheet(
        item: Binding<Activity?>(
          get: {
            if let id = editingActivityId {
              return viewModel.activities.first { $0.id == id }
            }
            return nil
          },
          set: { _ in editingActivityId = nil }
        )
      ) { activity in
        EditActivityView(
          activity: activity,
          categoryId: category.id,
          onDismiss: {
            editingActivityId = nil
          },
          onSave: { updatedActivity in
            viewModel.updateActivity(updatedActivity)
            editingActivityId = nil
          }
        )
      }
    }
    .onAppear {
      viewModel.loadCategory(category)
    }
  }
}

// MARK: - View Components
extension EditCategoryView {

  private var categorySection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Section header
      Text("Category Details")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.white)

      VStack(alignment: .leading, spacing: 12) {
        // Category name
        VStack(alignment: .leading, spacing: 8) {
          Text("Category Name")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)

          TextField("Category Name", text: $viewModel.categoryName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }

        // Activity count info with validation
        VStack(alignment: .leading, spacing: 8) {
          Text("Activities")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)

          HStack {
            Text("Count:")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text("\(viewModel.activities.count)")
              .font(.subheadline)
              .fontWeight(.medium)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(
                viewModel.activities.count >= 2
                  ? Color.blue.opacity(0.8)
                  : Color.orange.opacity(0.8)
              )
              .foregroundColor(.white)
              .cornerRadius(4)
          }

          // Warning message if less than 2 activities
          if viewModel.activities.count < 2 {
            Text("⚠️ Need at least 2 activities to save category")
              .font(.caption)
              .foregroundColor(.orange)
              .padding(.top, 2)
          }
        }
      }
      .padding(.vertical, 16)
      .padding(.horizontal, 16)
      .background(Color.white.opacity(0.1))
      .cornerRadius(12)
    }
  }

  private var activitiesSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Section header
      HStack {
        Text("Activities (\(viewModel.activities.count))")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.white)

        if viewModel.activities.count < 2 {
          Text("• Need 2+ to save")
            .font(.caption)
            .foregroundColor(.orange)
        }
      }

      VStack(spacing: 12) {
        // Add activity button
        Button(action: {
          showingAddActivity = true
        }) {
          HStack {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.blue)
            Text("Add New Activity")
              .foregroundColor(.white)
            Spacer()
          }
          .padding(.vertical, 12)
          .padding(.horizontal, 16)
          .background(Color.white.opacity(0.1))
          .cornerRadius(8)
        }

        // Activities list
        ForEach(viewModel.activities, id: \.id) { activity in
          ActivityRowView(
            activity: activity,
            onEdit: {
              editingActivityId = activity.id
            },
            onDelete: {
              activityToDelete = activity
              showingDeleteActivityAlert = true
            }
          )
          .padding(.vertical, 8)
          .padding(.horizontal, 16)
          .background(Color.white.opacity(0.1))
          .cornerRadius(8)
        }
      }
    }
  }

  private var dangerZoneSection: some View {
    VStack(alignment: .leading, spacing: 16) {

      VStack(spacing: 8) {
        Button(action: {
          showingDeleteCategoryAlert = true
        }) {
          HStack {
            Image(systemName: "trash")
            Text("Delete Category")
            Spacer()
          }
          .foregroundColor(.red)
          .padding(.vertical, 12)
          .padding(.horizontal, 16)
          .background(Color.white.opacity(0.1))
          .cornerRadius(8)
        }

      }
    }
  }
}

// MARK: - Activity Row Component
struct ActivityRowView: View {
  let activity: Activity
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      // Activity icon or image
      ActivityImageView(
        activity: activity,
        size: 32,
        cornerRadius: 6,
        defaultIcon: "📝"
      )

      // Activity details
      VStack(alignment: .leading, spacing: 2) {
        Text(activity.name)
          .font(.subheadline)
          .fontWeight(.medium)
      }

      Spacer()

      // Action buttons
      HStack(spacing: 8) {
        Button(action: onEdit) {
          Image(systemName: "pencil")
            .font(.caption)
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())

        Button(action: onDelete) {
          Image(systemName: "trash")
            .font(.caption)
            .foregroundColor(.red)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  EditCategoryView(
    category: Category(
      id: UUID(),
      userId: UUID(),
      name: "Sample Category",
      iconName: "📍",
      createdAt: Date()
    ),
    onDismiss: {},
    onSave: {}
  )
}
