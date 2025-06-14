import SwiftUI

/// Main profile screen displaying user information and settings
/// Uses separate component files with all business logic in ViewModel
struct ProfileView: View {
  @StateObject var viewModel = ProfileViewViewModel()
  @State private var showingEditProfile = false

  var body: some View {
    NavigationView {
      ZStack {
        // Reusable gradient background
        GradientBackground()

        VStack(spacing: 0) {
          // Profile header component
          ProfileHeaderView(
            userProfile: viewModel.userProfile,
            onEditTap: {
              showingEditProfile = true
            }
          )

          // Profile content component
          ProfileContentView(
            userProfile: viewModel.userProfile,
            onLogout: {
              Task {
                await viewModel.logOut()
              }
            }
          )
        }
      }
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear {
      Task {
        await viewModel.fetchCurrentUserProfile()
      }
    }
    .sheet(isPresented: $showingEditProfile) {
      EditProfileView(viewModel: viewModel)
    }
  }
}

// MARK: - Preview
#Preview {
  ProfileView()
}
