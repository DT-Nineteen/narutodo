import PhotosUI
import Supabase
import SwiftUI

struct EditActivityView: View {
  let activity: Activity
  let categoryId: UUID
  let onDismiss: () -> Void
  let onSave: (Activity) -> Void

  @StateObject private var viewModel = EditActivityViewModel()
  @State private var showingImagePicker = false
  @State private var selectedImage: PhotosPickerItem?

  var body: some View {
    NavigationView {
      Form {
        // Basic Information
        basicInfoSection

        // Icon/Image Section
        iconImageSection

        // Additional Details
        additionalDetailsSection
      }
      .navigationTitle("Edit Activity")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button("Cancel") {
            onDismiss()
          }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button("Save") {
            Task {
              await saveActivity()
            }
          }
          .disabled(
            viewModel.isLoading
              || viewModel.activityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
      .photosPicker(
        isPresented: $showingImagePicker,
        selection: $selectedImage,
        matching: .images
      )
      .onChange(of: selectedImage) { newItem in
        Task {
          await viewModel.loadSelectedImage(newItem)
        }
      }
    }
    .onAppear {
      viewModel.loadActivity(activity, categoryId: categoryId)
    }
  }
}

// View Components
extension EditActivityView {

  private var basicInfoSection: some View {
    Section("Activity Information") {
      // Activity name
      TextField("Activity Name", text: $viewModel.activityName)
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
  }

  private var iconImageSection: some View {
    Section("Icon or Image") {
      VStack(spacing: 12) {
        // Current icon/image display
        HStack {
          Text("Preview:")
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          // Preview display
          Group {
            if let image = viewModel.selectedUIImage {
              Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let imageUrl = viewModel.currentImageUrl, !imageUrl.isEmpty {
              // Show existing image from URL (placeholder for now)
              AsyncImage(url: URL(string: imageUrl)) { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              } placeholder: {
                ProgressView()
              }
              .frame(width: 50, height: 50)
              .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
              Text(viewModel.activityIcon.isEmpty ? "📝" : viewModel.activityIcon)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
          }
        }

        // Image picker button
        Button(action: {
          showingImagePicker = true
        }) {
          HStack {
            Image(systemName: "photo")
            Text("Choose New Image from Photos")
          }
          .foregroundColor(.blue)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
        }

        // Clear image button (if image is selected or exists)
        if viewModel.selectedUIImage != nil
          || (viewModel.currentImageUrl != nil && !viewModel.currentImageUrl!.isEmpty)
        {
          Button(action: {
            viewModel.clearSelectedImage()
          }) {
            Text("Remove Image")
              .foregroundColor(.red)
              .font(.caption)
          }
        }

        // Emoji picker section
        VStack(alignment: .leading, spacing: 8) {
          Text("Or choose an emoji:")
            .font(.subheadline)
            .foregroundColor(.secondary)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(viewModel.availableIcons, id: \.self) { icon in
                Button(action: {
                  viewModel.activityIcon = icon
                  viewModel.clearSelectedImage()  // Clear image when emoji is selected
                }) {
                  Text(icon)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(
                      viewModel.activityIcon == icon && viewModel.selectedUIImage == nil
                        && (viewModel.currentImageUrl?.isEmpty ?? true)
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear
                    )
                    .cornerRadius(6)
                }
              }
            }
            .padding(.horizontal, 4)
          }
        }
      }
    }
  }

  private var additionalDetailsSection: some View {
    Section("Additional Details") {
      // Activity metadata
      if let createdAt = viewModel.originalActivity?.createdAt {
        HStack {
          Text("Created:")
            .font(.caption)
            .foregroundColor(.secondary)

          Spacer()

          Text(formatDate(createdAt))
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // Loading indicator
      if viewModel.isLoading {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Updating activity...")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // Error message
      if let errorMessage = viewModel.errorMessage {
        Text("Error: \(errorMessage)")
          .font(.caption)
          .foregroundColor(.red)
      }
    }
  }

  // Actions
  private func saveActivity() async {
    let success = await viewModel.saveActivity()
    if success, let updatedActivity = viewModel.updatedActivity {
      onSave(updatedActivity)
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

// Edit Activity ViewModel
@MainActor
class EditActivityViewModel: ObservableObject {
  // Published Properties
  @Published var activityName: String = ""
  @Published var activityIcon: String = ""
  @Published var selectedUIImage: UIImage?
  @Published var currentImageUrl: String?
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  // Properties
  var originalActivity: Activity?
  var categoryId: UUID?
  var updatedActivity: Activity?
  private let activitiesService = ActivitiesViewModel()

  // Available Icons
  let availableIcons = [
    "📝", "📋", "📌", "📍", "🎯", "🎲", "🎮", "🎪", "🎭", "🎨",
    "🍜", "🍕", "🍔", "🍟", "🍗", "🍖", "🥘", "🍱", "🍙", "🍘",
    "🏃", "🚴", "🏊", "🏋️", "🤸", "🧘", "🏓", "🏸", "⚽", "🏀",
    "✈️", "🚗", "🚲", "🛵", "🚤", "⛵", "🚁", "🚀", "🎡", "🎢",
    "💻", "📱", "📚", "📖", "🎧", "🎸", "🎹", "🎤", "📺", "🎬",
    "💰", "💳", "🛍️", "🛒", "🎁", "💌", "📦", "📫", "📮", "💎",
    "🌟", "⭐", "✨", "🌙", "☀️", "⚡", "🔥", "💧", "🌈", "🎉",
  ]

  // Initialization
  func loadActivity(_ activity: Activity, categoryId: UUID) {
    print("📝 Loading activity for edit: \(activity.name)")

    self.originalActivity = activity
    self.categoryId = categoryId
    self.activityName = activity.name
    self.activityIcon = activity.iconName ?? ""
    self.currentImageUrl = activity.imageUrl
  }

  // Image Handling
  func loadSelectedImage(_ item: PhotosPickerItem?) async {
    guard let item = item else { return }

    isLoading = true
    errorMessage = nil

    do {
      if let data = try await item.loadTransferable(type: Data.self) {
        if let uiImage = UIImage(data: data) {
          self.selectedUIImage = uiImage
          self.activityIcon = ""  // Clear emoji when image is selected
          self.currentImageUrl = nil  // Clear existing image URL
          print("✅ New image loaded successfully")
        }
      }
    } catch {
      print("❌ Failed to load image: \(error)")
      self.errorMessage = "Failed to load image: \(error.localizedDescription)"
    }

    isLoading = false
  }

  func clearSelectedImage() {
    selectedUIImage = nil
    currentImageUrl = nil
    print("🗑️ Image cleared")
  }

  // Save Activity
  func saveActivity() async -> Bool {
    guard let originalActivity = originalActivity,
      let categoryId = categoryId
    else {
      print("❌ No original activity or category ID")
      errorMessage = "Invalid activity or category"
      return false
    }

    let trimmedName = activityName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      errorMessage = "Activity name is required"
      return false
    }

    isLoading = true
    errorMessage = nil

    do {
      // Handle image changes
      var newImageUrl: String?
      let session = try await SupabaseManager.shared.client.auth.session
      let userId = session.user.id

      if let newImage = selectedUIImage {
        // Upload new image
        print("📷 Starting new image upload to Supabase Storage...")

        // Convert UIImage to Data
        guard let imageData = newImage.jpegData(compressionQuality: 0.8) else {
          throw NSError(
            domain: "ImageError", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }

        // Delete old image if exists
        if let oldImageUrl = currentImageUrl, !oldImageUrl.isEmpty {
          await deleteOldImage(from: oldImageUrl, userId: userId, categoryId: categoryId)
        }

        // Create unique file path: userId/categoryId/timestamp.jpg
        let timestamp = Date().timeIntervalSince1970
        let filePath = "\(userId)/\(categoryId)/\(timestamp).jpg"

        do {
          // Upload new image to Supabase Storage
          try await SupabaseManager.shared.client.storage
            .from("activity.images")
            .upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))

          // Get public URL for the uploaded image
          let publicURL = try SupabaseManager.shared.client.storage
            .from("activity.images")
            .getPublicURL(path: filePath)

          newImageUrl = publicURL.absoluteString
          print("✅ New image uploaded successfully: \(newImageUrl ?? "N/A")")

        } catch {
          print("❌ Failed to upload new image: \(error)")
          throw NSError(
            domain: "ImageUploadError", code: 2,
            userInfo: [
              NSLocalizedDescriptionKey: "Failed to upload image: \(error.localizedDescription)"
            ])
        }

      } else if currentImageUrl != originalActivity.imageUrl {
        // Image was cleared (currentImageUrl is nil but original had an image)
        if let oldImageUrl = originalActivity.imageUrl, !oldImageUrl.isEmpty {
          await deleteOldImage(from: oldImageUrl, userId: userId, categoryId: categoryId)
        }
        newImageUrl = nil

      } else {
        // Keep existing image URL if no changes
        newImageUrl = currentImageUrl
      }

      // Create updated activity
      let updatedActivity = Activity(
        id: originalActivity.id,
        userId: originalActivity.userId,
        categoryId: categoryId,
        name: trimmedName,
        imageUrl: newImageUrl,
        iconName: newImageUrl != nil ? "🖼️" : (activityIcon.isEmpty ? "📝" : activityIcon),
        createdAt: originalActivity.createdAt
      )

      try await activitiesService.updateActivity(updatedActivity)
      self.updatedActivity = updatedActivity
      print("✅ Activity updated successfully: \(updatedActivity.name)")

      isLoading = false
      return true

    } catch {
      print("❌ Failed to update activity: \(error)")
      self.errorMessage = "Failed to update activity: \(error.localizedDescription)"
      isLoading = false
      return false
    }
  }

  // Helper Methods
  var hasUnsavedChanges: Bool {
    guard let original = originalActivity else { return false }

    let nameChanged = activityName.trimmingCharacters(in: .whitespacesAndNewlines) != original.name
    let iconChanged = activityIcon != (original.iconName ?? "")
    let imageChanged = selectedUIImage != nil || currentImageUrl != original.imageUrl

    return nameChanged || iconChanged || imageChanged
  }

  // Helper method to delete old image from Supabase Storage
  private func deleteOldImage(from imageUrl: String, userId: UUID, categoryId: UUID) async {
    // Extract file path from URL
    // URL format: https://xxx.supabase.co/storage/v1/object/public/activity.images/userId/categoryId/timestamp.jpg
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

      print("✅ Old image deleted successfully: \(filePath)")
    } catch {
      print("⚠️ Failed to delete old image (non-critical): \(error)")
      // Don't throw error as this is not critical for the main operation
    }
  }
}

#Preview {
  EditActivityView(
    activity: Activity(
      id: UUID(),
      userId: UUID(),
      categoryId: UUID(),
      name: "Sample Activity",
      imageUrl: nil,
      iconName: "📝",
      createdAt: Date()
    ),
    categoryId: UUID(),
    onDismiss: {},
    onSave: { _ in }
  )
}
