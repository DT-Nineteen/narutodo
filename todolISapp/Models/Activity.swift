import Foundation

struct Activity: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  let categoryId: UUID
  var name: String
  var imageUrl: String?
  var iconName: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case categoryId = "category_id"
    case name
    case imageUrl = "image_url"
    case iconName = "icon_name"
    case createdAt = "created_at"
  }
}

// MARK: - Extended Activity with Category Info
struct ActivityWithCategory: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  let categoryId: UUID
  var name: String
  var imageUrl: String?
  var iconName: String?
  let createdAt: Date

  // Category information
  let categoryName: String
  let categoryIcon: String?

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case categoryId = "category_id"
    case name
    case imageUrl = "image_url"
    case iconName = "icon_name"
    case createdAt = "created_at"
    case categoryName = "category_name"
    case categoryIcon = "category_icon"
  }
}
