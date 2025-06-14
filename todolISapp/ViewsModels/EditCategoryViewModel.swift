import Foundation
import SwiftUI

@MainActor
class EditCategoryViewModel: ObservableObject {
  // MARK: - Published Properties
  @Published var categoryName: String = ""
  @Published var activities: [Activity] = []
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  // MARK: - Private Properties
  private var originalCategory: Category?
  private let activitiesService = ActivitiesViewModel()

  // MARK: - Initialization
  func loadCategory(_ category: Category) {
    print("📝 Loading category for edit: \(category.name)")

    self.originalCategory = category
    self.categoryName = category.name

    // Load activities for this category
    Task {
      await loadActivities()
    }
  }

  // MARK: - Data Loading
  private func loadActivities() async {
    guard let category = originalCategory else {
      print("❌ No original category to load activities for")
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      let loadedActivities = try await activitiesService.fetchActivities(for: category.id)
      self.activities = loadedActivities
      print("✅ Loaded \(loadedActivities.count) activities for category '\(category.name)'")
    } catch {
      print("❌ Failed to load activities: \(error)")
      self.errorMessage = "Failed to load activities: \(error.localizedDescription)"
    }

    isLoading = false
  }

  // MARK: - Category Operations
  func saveCategory() async {
    guard let originalCategory = originalCategory else {
      print("❌ No original category to update")
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      let updatedCategory = Category(
        id: originalCategory.id,
        userId: originalCategory.userId,
        name: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
        iconName: originalCategory.iconName,  // Keep original icon
        createdAt: originalCategory.createdAt
      )

      try await activitiesService.updateCategory(updatedCategory)
      print("✅ Category updated successfully: \(updatedCategory.name)")

    } catch {
      print("❌ Failed to update category: \(error)")
      self.errorMessage = "Failed to update category: \(error.localizedDescription)"
    }

    isLoading = false
  }

  func deleteCategory() async {
    guard let originalCategory = originalCategory else {
      print("❌ No original category to delete")
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      // First delete all activities in this category
      for activity in activities {
        try await activitiesService.deleteActivity(activity.id)
      }

      // Then delete the category
      try await activitiesService.deleteCategory(originalCategory.id)
      print("✅ Category and all activities deleted successfully")

    } catch {
      print("❌ Failed to delete category: \(error)")
      self.errorMessage = "Failed to delete category: \(error.localizedDescription)"
    }

    isLoading = false
  }

  // MARK: - Activity Operations
  func addActivity(_ activity: Activity) {
    print("➕ Adding new activity: \(activity.name)")
    activities.append(activity)
  }

  func updateActivity(_ updatedActivity: Activity) {
    print("📝 Updating activity: \(updatedActivity.name)")

    if let index = activities.firstIndex(where: { $0.id == updatedActivity.id }) {
      activities[index] = updatedActivity
    }
  }

  func deleteActivity(_ activity: Activity) async {
    isLoading = true
    errorMessage = nil

    do {
      try await activitiesService.deleteActivity(activity.id)

      // Remove from local array
      activities.removeAll { $0.id == activity.id }
      print("✅ Activity deleted successfully: \(activity.name)")

    } catch {
      print("❌ Failed to delete activity: \(error)")
      self.errorMessage = "Failed to delete activity: \(error.localizedDescription)"
    }

    isLoading = false
  }

  // MARK: - Helper Methods
  func refreshData() async {
    await loadActivities()
  }

  var hasUnsavedChanges: Bool {
    guard let original = originalCategory else { return false }

    let nameChanged = categoryName.trimmingCharacters(in: .whitespacesAndNewlines) != original.name

    return nameChanged
  }
}
