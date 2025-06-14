import SwiftUI
import UIKit

// MARK: - View Extensions
extension View {
  /// Apply corner radius to specific corners of a view
  /// Used for creating rounded corners on specific sides only
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

// MARK: - Custom Shapes
/// Custom shape for applying corner radius to specific corners
/// Supports individual corner customization unlike standard cornerRadius
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
