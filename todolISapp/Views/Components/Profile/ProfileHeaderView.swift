import SwiftUI

/// Profile header component displaying user avatar, name and edit button
/// Handles the top section of profile with gradient background
struct ProfileHeaderView: View {
  let userProfile: Profile?
  let onEditTap: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Spacer().frame(height: 20)

      // Avatar with edit button
      ZStack {
        AsyncImage(url: URL(string: userProfile?.avatarUrl ?? "")) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Image(systemName: "person.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(Color.white, lineWidth: 3)
        )

        // Edit button on avatar
        Button(action: onEditTap) {
          Image(systemName: "pencil")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(Color.blue)
            .clipShape(Circle())
        }
        .offset(x: 35, y: 35)
      }

      // User name
      Text(userProfile?.fullName ?? "Loading...")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)

      Spacer().frame(height: 30)
    }
    .frame(height: 250)
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

    ProfileHeaderView(
      userProfile: Profile(
        id: UUID(),
        email: "john@example.com",
        fullName: "John Doe",
        avatarUrl: nil,
        updatedAt: nil,
        createdAt: Date()
      ),
      onEditTap: {
        print("Edit tapped")
      }
    )
  }
}
