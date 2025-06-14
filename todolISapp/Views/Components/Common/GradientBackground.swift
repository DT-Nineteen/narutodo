import SwiftUI

/// Reusable gradient background component
/// Provides consistent gradient styling across the app with customizable colors
struct GradientBackground: View {
  let colors: [Color]
  let startPoint: UnitPoint
  let endPoint: UnitPoint

  init(
    colors: [Color] = [Color.blue.opacity(0.8), Color.green.opacity(0.1)],
    startPoint: UnitPoint = .topLeading,
    endPoint: UnitPoint = .bottomTrailing
  ) {
    self.colors = colors
    self.startPoint = startPoint
    self.endPoint = endPoint
  }

  var body: some View {
    LinearGradient(
      gradient: Gradient(colors: colors),
      startPoint: startPoint,
      endPoint: endPoint
    )
    .ignoresSafeArea(.all)
  }
}

// MARK: - Preview
#Preview {
  GradientBackground()
}
