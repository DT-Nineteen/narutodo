import PhotosUI
import Supabase
import SwiftUI

struct AddActivityView: View {
  let categoryId: UUID
  let onDismiss: () -> Void
  let onSave: (Activity) -> Void

  @StateObject private var viewModel = AddActivityViewModel()
  @State private var showingImagePicker = false
  @State private var selectedImage: PhotosPickerItem?

  var body: some View {
    NavigationView {
      Form {
        // MARK: - Basic Information
        basicInfoSection

        // MARK: - Icon/Image Section
        iconImageSection

        // MARK: - Additional Details
        additionalDetailsSection
      }
      .navigationTitle("Add Activity")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            onDismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
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
      .onChange(of: selectedImage) { _, newItem in
        Task {
          await viewModel.loadSelectedImage(newItem)
        }
      }
    }
    .onAppear {
      viewModel.categoryId = categoryId
    }
  }
}

// MARK: - View Components
extension AddActivityView {

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
            Text("Choose Image from Photos")
          }
          .foregroundColor(.blue)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
        }

        // Clear image button (if image is selected)
        if viewModel.selectedUIImage != nil {
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
    Section("Status") {
      // Loading indicator
      if viewModel.isLoading {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Saving activity...")
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

  // MARK: - Actions
  private func saveActivity() async {
    let success = await viewModel.saveActivity()
    if success, let newActivity = viewModel.savedActivity {
      onSave(newActivity)
    }
  }
}

// MARK: - Add Activity ViewModel
@MainActor
class AddActivityViewModel: ObservableObject {
  // MARK: - Published Properties
  @Published var activityName: String = ""
  @Published var activityIcon: String = ""
  @Published var selectedUIImage: UIImage?
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  // MARK: - Properties
  var categoryId: UUID?
  var savedActivity: Activity?
  private let activitiesService = ActivitiesViewModel()

  // MARK: - Available Icons
  let availableIcons = [
    "📝", "📋", "📌", "📍", "🎯", "🎲", "🎮", "🎪", "🎭", "🎨",
    "🍜", "🍕", "🍔", "🍟", "🍗", "🍖", "🥘", "🍱", "🍙", "🍘",
    "🏃", "🚴", "🏊", "🏋️", "🤸", "🧘", "🏓", "🏸", "⚽", "🏀",
    "✈️", "🚗", "🚲", "🛵", "🚤", "⛵", "🚁", "🚀", "🎡", "🎢",
    "💻", "📱", "📚", "📖", "🎧", "🎸", "🎹", "🎤", "📺", "🎬",
    "💰", "💳", "🛍️", "🛒", "🎁", "💌", "📦", "📫", "📮", "💎",
    "🌟", "⭐", "✨", "🌙", "☀️", "⚡", "🔥", "💧", "🌈", "🎉",
  ]

  // MARK: - Image Handling
  func loadSelectedImage(_ item: PhotosPickerItem?) async {
    guard let item = item else { return }

    isLoading = true
    errorMessage = nil

    do {
      if let data = try await item.loadTransferable(type: Data.self) {
        if let uiImage = UIImage(data: data) {
          self.selectedUIImage = uiImage
          self.activityIcon = ""  // Clear emoji when image is selected
          print("✅ Image loaded successfully")
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
    print("🗑️ Image cleared")
  }

  // MARK: - Save Activity
  func saveActivity() async -> Bool {
    guard let categoryId = categoryId else {
      print("❌ No category ID provided")
      errorMessage = "Invalid category"
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
      // Get current user session
      let session = try await SupabaseManager.shared.client.auth.session
      let userId = session.user.id

      // Upload image if selected
      var imageUrl: String?
      if let image = selectedUIImage {
        print("📷 Starting image upload to Supabase Storage...")

        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
          throw NSError(
            domain: "ImageError", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }

        // Create unique file path: userId/categoryId/timestamp.jpg
        let timestamp = Date().timeIntervalSince1970
        let filePath = "\(userId)/\(categoryId)/\(timestamp).jpg"

        do {
          // Upload image to Supabase Storage
          try await SupabaseManager.shared.client.storage
            .from("activity.images")
            .upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))

          // Get public URL for the uploaded image
          let publicURL = try SupabaseManager.shared.client.storage
            .from("activity.images")
            .getPublicURL(path: filePath)

          imageUrl = publicURL.absoluteString
          print("✅ Image uploaded successfully: \(imageUrl ?? "N/A")")

        } catch {
          print("❌ Failed to upload image: \(error)")
          throw NSError(
            domain: "ImageUploadError", code: 2,
            userInfo: [
              NSLocalizedDescriptionKey: "Failed to upload image: \(error.localizedDescription)"
            ])
        }
      }

      // Create new activity
      let newActivity = Activity(
        id: UUID(),
        userId: userId,
        categoryId: categoryId,
        name: trimmedName,
        imageUrl: imageUrl,
        iconName: imageUrl != nil ? "🖼️" : (activityIcon.isEmpty ? "📝" : activityIcon),
        createdAt: Date()
      )

      try await activitiesService.createActivity(newActivity)
      self.savedActivity = newActivity
      print("✅ Activity created successfully: \(newActivity.name)")

      isLoading = false
      return true

    } catch {
      print("❌ Failed to create activity: \(error)")
      self.errorMessage = "Failed to create activity: \(error.localizedDescription)"
      isLoading = false
      return false
    }
  }
}

#Preview {
  AddActivityView(
    categoryId: UUID(),
    onDismiss: {},
    onSave: { _ in }
  )
}
