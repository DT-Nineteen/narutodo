import SwiftUI

struct ProfileView: View {
  @StateObject var viewModel = ProfileViewViewModel()
  @State private var showingEditProfile = false

  var body: some View {
    NavigationView {
      ZStack {
        // Full screen gradient background
        LinearGradient(
          gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.1)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)

        VStack(spacing: 0) {
          // Header section (without separate gradient background)
          VStack(spacing: 16) {
            Spacer().frame(height: 20)

            // Avatar with edit button
            ZStack {
              AsyncImage(url: URL(string: viewModel.userProfile?.avatarUrl ?? "")) { image in
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
              Button(action: {
                showingEditProfile = true
              }) {
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
            Text(viewModel.userProfile?.fullName ?? "Loading...")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.white)

            Spacer().frame(height: 30)
          }
          .frame(height: 250)

          // Content area with semi-transparent background
          VStack(spacing: 0) {
            // Profile info section
            VStack(spacing: 16) {
              ProfileInfoRow(
                title: "Email",
                value: viewModel.userProfile?.email ?? "",
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
                await viewModel.logOut()
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
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear {
      Task {
        await viewModel.fetchCurrentUserProfile()
      }
    }
    .sheet(isPresented: $showingEditProfile) {
      EditProfileSheet(viewModel: viewModel)
    }
  }
}

// MARK: - Supporting Views
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

struct ManagementButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.primary)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.secondary)
      }
      .padding(.vertical, 16)
      .padding(.horizontal, 20)
      .background(Color.gray.opacity(0.05))
      .cornerRadius(12)
    }
  }
}

// Extension for selective corner radius
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
  @ObservedObject var viewModel: ProfileViewViewModel
  @Environment(\.dismiss) private var dismiss

  @State private var editedName: String = ""
  @State private var editedAvatarUrl: String = ""

  var body: some View {
    NavigationView {
      ZStack {
        // Full screen gradient background for edit sheet too
        LinearGradient(
          gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.1)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)

        VStack(spacing: 24) {
          // Avatar preview
          VStack(spacing: 16) {
            AsyncImage(
              url: URL(
                string: editedAvatarUrl.isEmpty
                  ? (viewModel.userProfile?.avatarUrl ?? "") : editedAvatarUrl)
            ) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
              Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )

            Text("Tap to change avatar")
              .font(.caption)
              .foregroundColor(.white.opacity(0.8))
          }
          .padding(.top)

          // Form fields
          VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
              Text("Full Name")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

              TextField("Enter your name", text: $editedName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
              Text("Avatar URL")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

              TextField("Enter avatar URL", text: $editedAvatarUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
          }
          .padding(.horizontal)

          Spacer()
        }
      }
      .navigationTitle("Edit Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.white)
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button("Save") {
            Task {
              await saveProfile()
            }
          }
          .disabled(viewModel.isLoading)
          .foregroundColor(.white)
        }
      }
    }
    .onAppear {
      editedName = viewModel.userProfile?.fullName ?? ""
      editedAvatarUrl = viewModel.userProfile?.avatarUrl ?? ""
    }
  }

  private func saveProfile() async {
    // Update the profile with new values
    viewModel.userProfile?.fullName = editedName
    viewModel.userProfile?.avatarUrl = editedAvatarUrl.isEmpty ? nil : editedAvatarUrl

    // Call existing update function
    await viewModel.updateProfile()

    // Dismiss sheet if successful
    if viewModel.errorMessage == nil {
      dismiss()
    }
  }
}

#Preview {
  ProfileView()
}
