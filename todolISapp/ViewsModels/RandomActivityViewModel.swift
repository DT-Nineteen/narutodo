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

  // History and UI states
  @Published var showHistory: Bool = false
  @Published var activityHistory: [DatabaseRandomActivity] = []

  // Private Properties
  private let maxHistoryCount: Int = 10  // History limit
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
  func rollCategory(categoryId: UUID) {
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
      self.rollingStates[categoryId] = false
      self.checkAndSaveToHistory()
      print("🎯 \(category.name) result: \(self.selectedResults[categoryId]?.name ?? "nil")")
    }
  }

  /// Roll all category slots at once
  func rollAllSlots() {
    print("Rolling all slots...")

    for (index, category) in categories.enumerated() {
      // Stagger the rolling with small delays for better UX
      DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
        self.rollCategory(categoryId: category.id)
      }
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

  /// Toggle history view
  func toggleHistory() {
    showHistory.toggle()
    print("📚 History view: \(showHistory ? "shown" : "hidden")")
  }

  /// Clear all history
  func clearHistory() {
    activityHistory.removeAll()
    print("🗑️ Activity history cleared")
  }

  /// Refresh data from database
  func refreshData() async {
    print("🔄 Refreshing data from database...")
    await loadData()
  }

  // Private Helper Methods

  /// Get random activity from array
  private func getRandomActivity(from activities: [Activity]) -> Activity? {
    return activities.randomElement()
  }

  /// Check if all slots have results and save to history
  private func checkAndSaveToHistory() {
    // Only save to history if ALL categories have results
    guard !categories.isEmpty else { return }

    let allHaveResults = categories.allSatisfy { category in
      selectedResults[category.id] != nil
    }

    if allHaveResults {
      let completedActivity = DatabaseRandomActivity(
        categoryResults: selectedResults,
        categories: categories
      )

      addToHistory(completedActivity)
    }
  }

  /// Add activity to history
  private func addToHistory(_ activity: DatabaseRandomActivity) {
    activityHistory.insert(activity, at: 0)

    // Limit history count
    if activityHistory.count > maxHistoryCount {
      activityHistory.removeLast()
    }

    print("📝 Added to history. Total: \(activityHistory.count)")
  }

  /// Format date for display
  func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
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

  /// Check if has history
  var hasHistory: Bool {
    !activityHistory.isEmpty
  }

  /// Get formatted current time
  var currentTimeString: String {
    formatDate(Date())
  }

  /// Check if data is loaded and ready
  var isDataReady: Bool {
    !categories.isEmpty && !isLoading
  }

  /// Get result for specific category ID
  func getResult(for categoryId: UUID) -> Activity? {
    return selectedResults[categoryId]
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

// Database Random Activity Model
struct DatabaseRandomActivity {
  let categoryResults: [UUID: Activity]  // categoryId: selected activity
  let categories: [Category]  // for reference
  let generatedAt: Date

  init(categoryResults: [UUID: Activity], categories: [Category]) {
    self.categoryResults = categoryResults
    self.categories = categories
    self.generatedAt = Date()
  }

  /// Get result for a specific category
  func getResult(for categoryId: UUID) -> Activity? {
    return categoryResults[categoryId]
  }

  /// Get formatted results as string pairs for display
  var formattedResults: [(categoryName: String, activityName: String)] {
    return categories.compactMap { category in
      if let activity = categoryResults[category.id] {
        return (category.name, activity.name)
      }
      return nil
    }
  }
}
