import PhotosUI
import SwiftUI

/// Separate component for editing profile information
/// Handles profile editing with photo picker and form validation
struct EditProfileView: View {
  @ObservedObject var viewModel: ProfileViewViewModel
  @Environment(\.dismiss) private var dismiss

  @State private var editedName: String = ""
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var selectedImage: UIImage?

  var body: some View {
    NavigationView {
      ZStack {
        // Full screen gradient background for edit sheet too
        GradientBackground()

        VStack(spacing: 24) {
          // Avatar section
          avatarSection

          // Form fields section
          formFieldsSection

          // Error message display
          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(.system(size: 14))
              .foregroundColor(.red)
              .padding(.horizontal)
              .padding(.top, 8)
          }

          Spacer()

          // Loading indicator
          if viewModel.isLoading {
            loadingIndicator
          }
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
          if viewModel.isLoading {
            ProgressView()
              .scaleEffect(0.8)
              .tint(.white)
          } else {
            Button("Save") {
              Task {
                await saveProfile()
              }
            }
            .foregroundColor(.white)
          }
        }
      }
    }
    .onAppear {
      setupInitialValues()
    }
    .onChange(of: selectedPhoto) { newPhoto in
      Task {
        await loadSelectedPhoto(newPhoto)
      }
    }
  }
}

// MARK: - View Components
extension EditProfileView {

  private var avatarSection: some View {
    VStack(spacing: 16) {
      PhotosPicker(selection: $selectedPhoto, matching: .images) {
        Group {
          if let selectedImage = selectedImage {
            // Show selected image
            Image(uiImage: selectedImage)
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            // Show current avatar or placeholder
            AsyncImage(url: URL(string: viewModel.userProfile?.avatarUrl ?? "")) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            }
          }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
      }

      VStack(spacing: 8) {
        Text("Tap to change avatar")
          .font(.caption)
          .foregroundColor(.white.opacity(0.8))

        if selectedImage != nil {
          Button("Remove Photo") {
            selectedImage = nil
            selectedPhoto = nil
          }
          .font(.caption)
          .foregroundColor(.red.opacity(0.8))
        }
      }
    }
    .padding(.top)
  }

  private var formFieldsSection: some View {
    VStack(spacing: 20) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Full Name")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.white.opacity(0.8))

        TextField("Enter your name", text: $editedName)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .autocapitalization(.none)
          .disableAutocorrection(true)
      }
    }
    .padding(.horizontal)
  }

  private var loadingIndicator: some View {
    HStack {
      Spacer()
      ProgressView()
        .scaleEffect(1.2)
        .tint(.white)
      Spacer()
    }
    .padding()
  }
}

// MARK: - Private Methods
extension EditProfileView {

  private func setupInitialValues() {
    editedName = viewModel.userProfile?.fullName ?? ""
    print("🔍 EditProfileView appeared for user: \(viewModel.userProfile?.fullName ?? "Unknown")")
  }

  private func loadSelectedPhoto(_ newPhoto: PhotosPickerItem?) async {
    guard let newPhoto = newPhoto else { return }

    do {
      if let data = try await newPhoto.loadTransferable(type: Data.self),
        let image = UIImage(data: data)
      {
        selectedImage = image
        print("📷 Image selected successfully")
      }
    } catch {
      print("❌ Failed to load image: \(error)")
    }
  }

  private func saveProfile() async {
    print("💾 Starting profile save...")
    print("📝 New name: '\(editedName)'")
    print("📷 Has selected image: \(selectedImage != nil)")

    // Update name first if changed
    if editedName != viewModel.userProfile?.fullName {
      viewModel.userProfile?.fullName = editedName
    }

    // Call update function with avatar only
    await viewModel.updateProfile(newAvatar: selectedImage)

    // Dismiss sheet if successful
    if viewModel.errorMessage == nil {
      print("✅ Profile saved successfully, dismissing sheet")
      dismiss()
    } else {
      print("❌ Profile save failed: \(viewModel.errorMessage ?? "Unknown error")")
    }
  }
}

// MARK: - Preview
#Preview {
  EditProfileView(viewModel: ProfileViewViewModel())
}
