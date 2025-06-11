import Foundation
import Supabase

@MainActor
class ActivitiesViewModel: ObservableObject {
  @Published var activities: [Activity] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  // save the category that this ViewModel is managing (optional for generic usage)
  private let category: Category?

  // ViewModel can be initialized with a specific category or without for generic operations
  init(category: Category? = nil) {
    self.category = category
  }

  // READ: get all activities for this category
  func fetchActivities() async {
    guard let category = self.category else {
      print("❌ No category set for fetching activities")
      return
    }

    self.isLoading = true
    self.errorMessage = nil

    do {
      let fetchedActivities: [Activity] = try await SupabaseManager.shared.client
        .from("activities")
        .select()
        .eq("category_id", value: category.id)  // filter by category id
        .order("created_at", ascending: false)
        .execute()
        .value
      self.activities = fetchedActivities
    } catch {
      self.errorMessage = error.localizedDescription
      print(
        "Error fetching activities for category \(category.name): \(error.localizedDescription)"
      )
    }

    self.isLoading = false
  }

  // READ: get activities for a specific category (generic method)
  func fetchActivities(for categoryId: UUID) async throws -> [Activity] {
    do {
      let fetchedActivities: [Activity] = try await SupabaseManager.shared.client
        .from("activities")
        .select()
        .eq("category_id", value: categoryId)
        .order("created_at", ascending: false)
        .execute()
        .value

      print("✅ Fetched \(fetchedActivities.count) activities for category \(categoryId)")
      return fetchedActivities
    } catch {
      print("❌ Error fetching activities for category \(categoryId): \(error)")
      throw error
    }
  }

  // CREATE: add a new activity to this category
  func addActivity(name: String, image: Data?, icon: String?) async {
    guard let category = self.category else {
      print("❌ No category set for adding activity")
      return
    }

    do {
      let session = try await SupabaseManager.shared.client.auth.session
      let userId = session.user.id

      self.isLoading = true
      var imageUrlString: String? = nil

      // 1. Upload image if there is one
      if let imageData = image {
        let filePath = "\(userId)/\(category.id)/\(Date().timeIntervalSince1970).jpg"
        do {
          try await SupabaseManager.shared.client.storage
            .from("activity.images")
            .upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))

          let response = try SupabaseManager.shared.client.storage
            .from("activity.images")
            .getPublicURL(path: filePath)
          imageUrlString = response.absoluteString
        } catch {
          self.errorMessage = error.localizedDescription
          self.isLoading = false
          return
        }
      }

      // 2. prepare data to insert into DB
      struct NewActivity: Encodable {
        let name: String, user_id: UUID, category_id: UUID, image_url: String?, icon_name: String?
      }

      let newActivity = NewActivity(
        name: name,
        user_id: userId,
        category_id: category.id,  // get id from the category that is saved
        image_url: imageUrlString,
        icon_name: icon
      )

      // 3. insert into database
      let addedActivity: [Activity] = try await SupabaseManager.shared.client
        .from("activities")
        .insert(newActivity, returning: .representation)
        .select()
        .execute()
        .value

      if let activity = addedActivity.first {
        self.activities.insert(activity, at: 0)  // add to the beginning of the list for better UI
      }
    } catch {
      self.errorMessage = error.localizedDescription
    }
    self.isLoading = false
  }

  // CREATE: create a new activity (generic method)
  func createActivity(_ activity: Activity) async throws {
    do {
      let session = try await SupabaseManager.shared.client.auth.session
      let userId = session.user.id

      // Prepare data to insert into DB
      struct NewActivity: Encodable {
        let id: UUID
        let name: String
        let user_id: UUID
        let category_id: UUID
        let image_url: String?
        let icon_name: String?
        let created_at: Date
      }

      let newActivity = NewActivity(
        id: activity.id,
        name: activity.name,
        user_id: userId,
        category_id: activity.categoryId,
        image_url: activity.imageUrl,
        icon_name: activity.iconName,
        created_at: activity.createdAt
      )

      // Insert into database
      try await SupabaseManager.shared.client
        .from("activities")
        .insert(newActivity)
        .execute()

      print("✅ Activity created successfully: \(activity.name)")
    } catch {
      print("❌ Error creating activity: \(error)")
      throw error
    }
  }

  // UPDATE: update an existing activity
  func updateActivity(_ activity: Activity) async throws {
    do {
      // Prepare data to update in DB
      struct UpdateActivity: Encodable {
        let name: String
        let icon_name: String?
        let image_url: String?
      }

      let updateData = UpdateActivity(
        name: activity.name,
        icon_name: activity.iconName,
        image_url: activity.imageUrl
      )

      try await SupabaseManager.shared.client
        .from("activities")
        .update(updateData)
        .eq("id", value: activity.id)
        .execute()

      print("✅ Activity updated successfully: \(activity.name)")
    } catch {
      print("❌ Error updating activity: \(error)")
      throw error
    }
  }

  // DELETE: delete an activity
  func deleteActivity(id: UUID) async {
    do {
      try await SupabaseManager.shared.client
        .from("activities")
        .delete()
        .eq("id", value: id)
        .execute()

      activities.removeAll { $0.id == id }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  // DELETE: delete an activity (generic method)
  func deleteActivity(_ activityId: UUID) async throws {
    do {
      // First, get the activity to check if it has an image to delete
      let activityToDelete: Activity = try await SupabaseManager.shared.client
        .from("activities")
        .select()
        .eq("id", value: activityId)
        .single()
        .execute()
        .value

      // Delete the activity from database
      try await SupabaseManager.shared.client
        .from("activities")
        .delete()
        .eq("id", value: activityId)
        .execute()

      // Delete associated image if exists
      if let imageUrl = activityToDelete.imageUrl, !imageUrl.isEmpty {
        await deleteActivityImage(
          from: imageUrl, userId: activityToDelete.userId, categoryId: activityToDelete.categoryId)
      }

      print("✅ Activity deleted successfully: \(activityId)")
    } catch {
      print("❌ Error deleting activity: \(error)")
      throw error
    }
  }

  // Helper method to delete activity image from Supabase Storage
  private func deleteActivityImage(from imageUrl: String, userId: UUID, categoryId: UUID) async {
    // Extract file path from URL
    guard let url = URL(string: imageUrl),
      let pathComponents = url.pathComponents.last
    else {
      print("⚠️ Could not extract file path from image URL: \(imageUrl)")
      return
    }

    // Reconstruct the file path
    let filePath = "\(userId)/\(categoryId)/\(pathComponents)"

    do {
      try await SupabaseManager.shared.client.storage
        .from("activity.images")
        .remove(paths: [filePath])

      print("✅ Activity image deleted successfully: \(filePath)")
    } catch {
      print("⚠️ Failed to delete activity image (non-critical): \(error)")
      // Don't throw error as this is not critical for the main operation
    }
  }

  // MARK: - Category Operations

  // READ: get all categories for current user
  func fetchCategories() async throws -> [Category] {
    do {
      let fetchedCategories: [Category] = try await SupabaseManager.shared.client
        .from("categories")
        .select()
        .order("created_at", ascending: false)
        .execute()
        .value

      print("✅ Fetched \(fetchedCategories.count) categories")
      return fetchedCategories
    } catch {
      print("❌ Error fetching categories: \(error)")
      throw error
    }
  }

  // UPDATE: update a category
  func updateCategory(_ category: Category) async throws {
    do {
      // Prepare data to update in DB
      struct UpdateCategory: Encodable {
        let name: String
        let icon_name: String?
      }

      let updateData = UpdateCategory(
        name: category.name,
        icon_name: category.iconName
      )

      try await SupabaseManager.shared.client
        .from("categories")
        .update(updateData)
        .eq("id", value: category.id)
        .execute()

      print("✅ Category updated successfully: \(category.name)")
    } catch {
      print("❌ Error updating category: \(error)")
      throw error
    }
  }

  // DELETE: delete a category
  func deleteCategory(_ categoryId: UUID) async throws {
    do {
      // First, get all activities in this category to delete their images
      let activitiesInCategory = try await fetchActivities(for: categoryId)

      // Delete the category from database (this will cascade delete activities due to FK constraint)
      try await SupabaseManager.shared.client
        .from("categories")
        .delete()
        .eq("id", value: categoryId)
        .execute()

      // Delete all associated images
      for activity in activitiesInCategory {
        if let imageUrl = activity.imageUrl, !imageUrl.isEmpty {
          await deleteActivityImage(
            from: imageUrl, userId: activity.userId, categoryId: activity.categoryId)
        }
      }

      print("✅ Category and all associated data deleted successfully: \(categoryId)")
    } catch {
      print("❌ Error deleting category: \(error)")
      throw error
    }
  }
}
