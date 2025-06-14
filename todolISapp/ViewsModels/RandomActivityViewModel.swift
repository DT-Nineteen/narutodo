//
//  RandomActivityViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import Foundation
import Supabase
import SwiftUI

// Random Activity ViewModel
@MainActor
class RandomActivityViewModel: ObservableObject {

  // Published Properties for Categories and Activities
  @Published var categories: [Category] = []
  @Published var categorizedActivities: [UUID: [Activity]] = [:]  // categoryId: [Activity]

  // Dynamic rolling states - key is category ID
  @Published var rollingStates: [UUID: Bool] = [:]

  // Dynamic results - key is category ID, value is selected activity
  @Published var selectedResults: [UUID: Activity] = [:]

  // Loading and error states
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  // Private Properties
  private let rollingDuration: Double = 2.0  // Rolling animation duration

  // Initialization - Dattebayo!
  init() {
    print("RandomActivityViewModel initialized")
    Task {
      await loadData()
    }
  }

  // Data Loading Methods

  /// Load categories and activities from database
  func loadData() async {
    print("Loading categories and activities from database...")
    self.isLoading = true
    self.errorMessage = nil

    do {
      // Get current user session
      let session = try await SupabaseManager.shared.client.auth.session
      let userId = session.user.id

      // 1. Fetch all categories for current user
      let fetchedCategories: [Category] = try await SupabaseManager.shared.client
        .from("categories")
        .select()
        .eq("user_id", value: userId)
        .order("created_at", ascending: true)
        .execute()
        .value

      self.categories = fetchedCategories
      print("Loaded \(fetchedCategories.count) categories")

      // 2. Initialize rolling states for all categories
      self.rollingStates = [:]
      self.selectedResults = [:]

      // 3. Fetch activities for each category
      for category in fetchedCategories {
        let activities: [Activity] = try await SupabaseManager.shared.client
          .from("activities")
          .select()
          .eq("category_id", value: category.id)
          .execute()
          .value

        self.categorizedActivities[category.id] = activities
        self.rollingStates[category.id] = false
        print("Loaded \(activities.count) activities for category '\(category.name)'")
      }

    } catch {
      self.errorMessage = error.localizedDescription
      print("❌ Error loading data: \(error.localizedDescription)")
    }

    self.isLoading = false
  }

  // Dynamic Slot Rolling Methods

  /// Roll a specific category slot by category ID
  func rollCategory(
    categoryId: UUID, completion: @escaping (_ result: Activity, _ category: Category) -> Void
  ) {
    guard let category = categories.first(where: { $0.id == categoryId }) else {
      print("Category not found for ID: \(categoryId)")
      return
    }

    print("🎰 Rolling slot for category: \(category.name)")
    rollingStates[categoryId] = true

    let activities = categorizedActivities[categoryId] ?? []

    // Add rolling delay for casino effect
    DispatchQueue.main.asyncAfter(deadline: .now() + rollingDuration) {
      self.selectedResults[categoryId] = self.getRandomActivity(from: activities)
      if let result = self.selectedResults[categoryId] {
        completion(result, category)
        print("🎯 \(category.name) result: \(result.name)")
      } else {
        print("🎯 No result found for category: \(category.name)")
      }
      self.rollingStates[categoryId] = false
    }
  }

  /// Reset a specific category slot
  func resetSlot(categoryId: UUID) {
    selectedResults[categoryId] = nil
    if let category = categories.first(where: { $0.id == categoryId }) {
      print("🔄 Reset slot for category: \(category.name)")
    }
  }

  /// Reset all slots
  func resetAllSlots() {
    selectedResults.removeAll()
    print("🔄 Reset all slots")
  }

  /// Refresh data from database
  func refreshData() async {
    print("🔄 Refreshing data from database...")
    await loadData()
  }

  /// Delete a category and all its activities
  func deleteCategory(categoryId: UUID) async {
    print("🗑️ Deleting category: \(categoryId)")

    do {
      let session = try await SupabaseManager.shared.client.auth.session
      let userId = session.user.id

      // Delete from database (this will cascade delete activities due to FK constraint)
      try await SupabaseManager.shared.client
        .from("categories")
        .delete()
        .eq("id", value: categoryId)
        .eq("user_id", value: userId)
        .execute()

      // Remove from local arrays
      categories.removeAll { $0.id == categoryId }
      categorizedActivities.removeValue(forKey: categoryId)
      rollingStates.removeValue(forKey: categoryId)
      selectedResults.removeValue(forKey: categoryId)

      print("✅ Category deleted successfully")

    } catch {
      self.errorMessage = "Failed to delete category: \(error.localizedDescription)"
      print("❌ Error deleting category: \(error)")
    }
  }

  // Private Helper Methods

  /// Get random activity from array
  private func getRandomActivity(from activities: [Activity]) -> Activity? {
    return activities.randomElement()
  }

  /// Get activities for a specific category by ID
  func getActivities(for categoryId: UUID) -> [Activity] {
    return categorizedActivities[categoryId] ?? []
  }

  /// Get category by ID
  func getCategory(for categoryId: UUID) -> Category? {
    return categories.first { $0.id == categoryId }
  }
}

// State Extensions
extension RandomActivityViewModel {
  /// Check if any slot is currently rolling
  var isAnySlotRolling: Bool {
    rollingStates.values.contains(true)
  }

  /// Check if all slots have results
  var allSlotsComplete: Bool {
    guard !categories.isEmpty else { return false }
    return categories.allSatisfy { category in
      selectedResults[category.id] != nil
    }
  }

  /// Check if any slot has result
  var hasAnyResult: Bool {
    !selectedResults.isEmpty
  }

  /// Check if data is loaded and ready
  var isDataReady: Bool {
    !categories.isEmpty && !isLoading
  }

  /// Get result for specific category ID
  func getResult(for categoryId: UUID) -> Activity? {
    return selectedResults[categoryId]
  }

  /// Check if category has enough activities for randomization (minimum 2)
  func hasEnoughActivities(for categoryId: UUID) -> Bool {
    let activities = categorizedActivities[categoryId] ?? []
    return activities.count >= 2
  }

  /// Get activities count for a specific category
  func getActivitiesCount(for categoryId: UUID) -> Int {
    return categorizedActivities[categoryId]?.count ?? 0
  }

  /// Check if specific category is rolling
  func isRolling(categoryId: UUID) -> Bool {
    return rollingStates[categoryId] ?? false
  }

  /// Get total number of categories
  var totalCategories: Int {
    return categories.count
  }

  /// Get number of completed slots
  var completedSlotsCount: Int {
    return selectedResults.count
  }
}
