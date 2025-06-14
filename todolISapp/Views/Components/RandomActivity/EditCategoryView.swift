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
      Form {
        // MARK: - Category Section
        categorySection

        // MARK: - Activities Section
        activitiesSection

        // MARK: - Danger Zone
        dangerZoneSection
      }
      .navigationTitle("Edit Category")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button("Cancel") {
            onDismiss()
          }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button("Save") {
            Task {
              await viewModel.saveCategory()
              onSave()
            }
          }
          .disabled(
            viewModel.isLoading
              || viewModel.categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    Section("Category Details") {
      VStack(alignment: .leading, spacing: 8) {
        // Category name
        TextField("Category Name", text: $viewModel.categoryName)
          .textFieldStyle(RoundedBorderTextFieldStyle())

        // Category icon picker
        HStack {
          Text("Icon:")
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          HStack(spacing: 12) {
            // Current icon display
            Text(viewModel.categoryIcon.isEmpty ? "📂" : viewModel.categoryIcon)
              .font(.title2)
              .frame(width: 40, height: 40)
              .background(Color.gray.opacity(0.1))
              .cornerRadius(8)

            // Icon picker buttons
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(viewModel.availableIcons, id: \.self) { icon in
                  Button(action: {
                    viewModel.categoryIcon = icon
                  }) {
                    Text(icon)
                      .font(.title3)
                      .frame(width: 32, height: 32)
                      .background(
                        viewModel.categoryIcon == icon
                          ? Color.accentColor.opacity(0.2)
                          : Color.clear
                      )
                      .cornerRadius(6)
                  }
                }
              }
              .padding(.horizontal, 4)
            }
          }
        }

        // Activity count info
        HStack {
          Text("Activities:")
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          Text("\(viewModel.activities.count)")
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(4)
        }
      }
    }
  }

  private var activitiesSection: some View {
    Section {
      // Add activity button
      Button(action: {
        showingAddActivity = true
      }) {
        HStack {
          Image(systemName: "plus.circle.fill")
            .foregroundColor(.green)
          Text("Add New Activity")
            .foregroundColor(.primary)
          Spacer()
        }
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
      }
    } header: {
      Text("Activities (\(viewModel.activities.count))")
    }
  }

  private var dangerZoneSection: some View {
    Section {
      Button(action: {
        showingDeleteCategoryAlert = true
      }) {
        HStack {
          Image(systemName: "trash")
          Text("Delete Category")
          Spacer()
        }
        .foregroundColor(.red)
      }
    } header: {
      Text("Danger Zone")
    } footer: {
      Text("Deleting this category will permanently remove it and all its activities.")
        .font(.caption)
        .foregroundColor(.secondary)
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
