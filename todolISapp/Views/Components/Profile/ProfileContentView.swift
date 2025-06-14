import SwiftUI

/// Profile content area component displaying user info and actions
/// Handles the lower section with semi-transparent background and user details
struct ProfileContentView: View {
  let userProfile: Profile?
  let onLogout: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      // Profile info section
      VStack(spacing: 16) {
        ProfileInfoRow(
          title: "Email",
          value: userProfile?.email ?? "",
          showEditIcon: false
        )
      }
      .padding(.horizontal, 20)
      .padding(.top, 30)

      Spacer().frame(height: 40)

      Spacer()

      // Log out button
      Button(action: {
        Task {
          onLogout()
        }
      }) {
        Text("Log out")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.primary)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(Color.white.opacity(0.2))
          .cornerRadius(12)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 30)
    }
    .background(Color.white.opacity(0.1))
    .cornerRadius(25, corners: [.topLeft, .topRight])
  }
}

/// Reusable component for displaying profile information rows
/// Shows title, value and optional edit icon with consistent styling
struct ProfileInfoRow: View {
  let title: String
  let value: String
  let showEditIcon: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white.opacity(0.8))

      HStack {
        Text(value)
          .font(.system(size: 16))
          .foregroundColor(.white)

        Spacer()

        if showEditIcon {
          Image(systemName: "pencil")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.6))
        }
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 16)
      .background(Color.white.opacity(0.1))
      .cornerRadius(12)
    }
  }
}

// MARK: - Preview
#Preview {
  ZStack {
    LinearGradient(
      gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.1)]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea(.all)

    ProfileContentView(
      userProfile: Profile(
        id: UUID(),
        email: "john@example.com",
        fullName: "John Doe",
        avatarUrl: nil,
        updatedAt: nil,
        createdAt: Date()
      ),
      onLogout: {
        print("Logout tapped")
      }
    )
  }
}
