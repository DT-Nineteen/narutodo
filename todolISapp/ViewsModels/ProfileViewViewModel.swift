//
//  ProfileViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import Foundation
import Supabase
import UIKit

/// ViewModel for Profile functionality with all business logic included
/// Simplified approach for small project - all logic in ViewModel
@MainActor
class ProfileViewViewModel: ObservableObject {
  @Published var userProfile: Profile?
  @Published var isLoading = false
  @Published var errorMessage: String?

  // MARK: - Fetch Profile
  /// Fetches current user profile from database
  func fetchCurrentUserProfile() async {
    print("🔍 ProfileViewModel: Starting profile fetch...")

    isLoading = true
    errorMessage = nil

    do {
      let session = try await SupabaseManager.shared.client.auth.session
      let currentUserId = session.user.id

      print("🔍 ProfileViewModel: User ID: \(currentUserId)")

      let profile: Profile = try await SupabaseManager.shared.client
        .from("profiles")
        .select()
        .eq("id", value: currentUserId)
        .single()
        .execute()
        .value

      userProfile = profile
      isLoading = false

      print("✅ ProfileViewModel: Profile fetched successfully for \(profile.fullName ?? "Unknown")")

    } catch {
      print("❌ ProfileViewModel: Error fetching profile: \(error)")

      errorMessage = error.localizedDescription
      isLoading = false
    }
  }

  // MARK: - Update Profile
  /// Updates profile with avatar upload logic included
  /// Handles both profile info and avatar updates
  func updateProfile(newAvatar: UIImage? = nil) async {
    guard let profileToUpdate = userProfile else {
      errorMessage = "Cannot find profile to update."
      return
    }

    print("💾 ProfileViewModel: Starting profile update...")

    isLoading = true
    errorMessage = nil

    do {
      var updatedProfile = profileToUpdate

      // Handle avatar upload if new image is provided
      if let avatarImage = newAvatar {
        print("📷 ProfileViewModel: Starting avatar upload...")

        let session = try await SupabaseManager.shared.client.auth.session
        let userId = session.user.id

        // Convert UIImage to Data
        guard let imageData = avatarImage.jpegData(compressionQuality: 0.8) else {
          throw NSError(
            domain: "ImageError", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }

        // Delete old avatar if exists
        if let oldAvatarUrl = profileToUpdate.avatarUrl, !oldAvatarUrl.isEmpty {
          await deleteOldAvatar(from: oldAvatarUrl, userId: userId)
        }

        // Create unique file path: profiles/userId/timestamp.jpg
        let timestamp = Date().timeIntervalSince1970
        let filePath = "profiles/\(userId)/\(timestamp).jpg"

        do {
          // Upload image to Supabase Storage
          try await SupabaseManager.shared.client.storage
            .from("profiles.avatars")
            .upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))

          // Get public URL for the uploaded image
          let publicURL = try SupabaseManager.shared.client.storage
            .from("profiles.avatars")
            .getPublicURL(path: filePath)

          updatedProfile.avatarUrl = publicURL.absoluteString
          print("✅ ProfileViewModel: Avatar uploaded successfully: \(publicURL.absoluteString)")

        } catch {
          print("❌ ProfileViewModel: Failed to upload avatar: \(error)")
          throw NSError(
            domain: "AvatarUploadError", code: 2,
            userInfo: [
              NSLocalizedDescriptionKey: "Failed to upload avatar: \(error.localizedDescription)"
            ])
        }
      }

      // Update profile in database
      struct ProfileUpdate: Encodable {
        let full_name: String?
        let avatar_url: String?
      }

      let updateData = ProfileUpdate(
        full_name: updatedProfile.fullName,
        avatar_url: updatedProfile.avatarUrl
      )

      try await SupabaseManager.shared.client
        .from("profiles")
        .update(updateData)
        .eq("id", value: profileToUpdate.id)
        .execute()

      print("✅ ProfileViewModel: Profile updated successfully!")

      // Update local profile and refresh from database
      userProfile = updatedProfile

      // Fetch fresh data to ensure sync
      await fetchCurrentUserProfile()

    } catch {
      print("❌ ProfileViewModel: Error updating profile: \(error)")

      errorMessage = error.localizedDescription
      isLoading = false
    }
  }

  // MARK: - Helper Methods
  /// Deletes old avatar from Supabase Storage
  private func deleteOldAvatar(from avatarUrl: String, userId: UUID) async {
    print("🗑️ ProfileViewModel: Attempting to delete old avatar...")

    // Extract file path from URL
    // URL format: https://xxx.supabase.co/storage/v1/object/public/profiles.avatars/profiles/userId/timestamp.jpg
    guard let url = URL(string: avatarUrl),
      url.pathComponents.count > 5
    else {
      print("⚠️ ProfileViewModel: Could not extract file path from URL: \(avatarUrl)")
      return
    }

    // Extract path after "/storage/v1/object/public/profiles.avatars/"
    let pathComponents = url.pathComponents.dropFirst(5).joined(separator: "/")
    let filePath = pathComponents

    do {
      try await SupabaseManager.shared.client.storage
        .from("profiles.avatars")
        .remove(paths: [filePath])

      print("✅ ProfileViewModel: Old avatar deleted successfully: \(filePath)")
    } catch {
      print("⚠️ ProfileViewModel: Failed to delete old avatar (non-critical): \(error)")
      // Don't throw error as this is not critical for the main operation
    }
  }

  // MARK: - Logout
  /// Logs out the current user
  func logOut() async {
    print("🔍 ProfileViewModel: Starting logout...")

    do {
      try await SupabaseManager.shared.client.auth.signOut()
      print("✅ ProfileViewModel: User logged out successfully")
    } catch {
      print("❌ ProfileViewModel: Error logging out: \(error)")

      errorMessage = error.localizedDescription
    }
  }
}
