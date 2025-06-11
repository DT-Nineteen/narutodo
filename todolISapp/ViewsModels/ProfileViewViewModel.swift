//
//  ProfileViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import Foundation
import Supabase

class ProfileViewViewModel: ObservableObject {
  @Published var userProfile: Profile?
  @Published var isLoading = false
  @Published var errorMessage: String?

  // Fetch current user profile
  func fetchCurrentUserProfile() async {
    do {
      let session = try await SupabaseManager.shared.client.auth.session
      let currentUserId = session.user.id

      print("🔍 Fetching profile for user: \(currentUserId), session.user.id: \(session.user)")

      isLoading = true
      errorMessage = nil

      let profile: Profile = try await SupabaseManager.shared.client
        .from("profiles")
        .select()
        .eq("id", value: currentUserId)
        .single()
        .execute()
        .value

      self.userProfile = profile

    } catch {
      print("Error fetching profile: \(error)")
      self.errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func updateProfile() async {
    guard let profileToUpdate = userProfile else {
      errorMessage = "Cannot find profile to update."
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      try await SupabaseManager.shared.client
        .from("profiles")
        .update(profileToUpdate)
        .eq("id", value: profileToUpdate.id)
        .execute()

      print("✅ Update profile successfully!")
    } catch {
      print("Error update profile: \(error)")
      self.errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func logOut() async {
    do {
      print("🔍 Logging out user: )")
      try await SupabaseManager.shared.client.auth.signOut()
    } catch {
      print("Error logging out: \(error)")
    }
  }
}
