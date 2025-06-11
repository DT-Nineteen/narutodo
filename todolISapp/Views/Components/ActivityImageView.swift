import SwiftUI

/// Reusable component to display activity image or fallback to icon
/// Handles AsyncImage loading with proper fallbacks and consistent styling
struct ActivityImageView: View {
  let activity: Activity
  let size: CGFloat
  let cornerRadius: CGFloat
  let defaultIcon: String
  let backgroundColor: Color?

  init(
    activity: Activity,
    size: CGFloat = 32,
    cornerRadius: CGFloat = 6,
    defaultIcon: String = "📝",
    backgroundColor: Color? = nil
  ) {
    self.activity = activity
    self.size = size
    self.cornerRadius = cornerRadius
    self.defaultIcon = defaultIcon
    self.backgroundColor = backgroundColor
  }

  var body: some View {
    Group {
      if let imageUrl = activity.imageUrl, !imageUrl.isEmpty {
        // Show actual image from URL
        AsyncImage(url: URL(string: imageUrl)) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          // Loading placeholder
          ProgressView()
            .scaleEffect(0.6)
            .frame(width: size, height: size)
            .background(backgroundColor ?? Color.gray.opacity(0.1))
            .cornerRadius(cornerRadius)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      } else {
        // Fallback to icon/emoji
        Text(activity.iconName ?? defaultIcon)
          .font(getFontSize())
          .frame(width: size, height: size)
          .background(backgroundColor ?? Color.gray.opacity(0.1))
          .cornerRadius(cornerRadius)
      }
    }
  }

  private func getFontSize() -> Font {
    switch size {
    case 0..<25:
      return .caption
    case 25..<35:
      return .title3
    case 35..<45:
      return .title2
    default:
      return .title
    }
  }
}

// MARK: - Preview
#Preview {
  VStack(spacing: 16) {
    // Activity with image
    ActivityImageView(
      activity: Activity(
        id: UUID(),
        userId: UUID(),
        categoryId: UUID(),
        name: "Sample Activity",
        imageUrl: "https://picsum.photos/100/100",
        iconName: "🎮",
        createdAt: Date()
      ),
      size: 50,
      cornerRadius: 10
    )

    // Activity with just icon
    ActivityImageView(
      activity: Activity(
        id: UUID(),
        userId: UUID(),
        categoryId: UUID(),
        name: "Sample Activity",
        imageUrl: nil,
        iconName: "🎮",
        createdAt: Date()
      ),
      size: 32,
      cornerRadius: 6
    )

    // Activity with default fallback
    ActivityImageView(
      activity: Activity(
        id: UUID(),
        userId: UUID(),
        categoryId: UUID(),
        name: "Sample Activity",
        imageUrl: nil,
        iconName: nil,
        createdAt: Date()
      ),
      size: 24,
      cornerRadius: 4
    )
  }
  .padding()
}
