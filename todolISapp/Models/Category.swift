import Foundation

struct Category: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  var name: String
  var iconName: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case name
    case iconName = "icon_name"
    case createdAt = "created_at"
  }
}

// MARK: - Supporting Models for Requests

struct NewCategoryRequest: Encodable {
  let name: String
  let user_id: UUID
  let icon_name: String?
}

struct UpdateCategoryRequest: Encodable {
  let name: String
  let icon_name: String?
}
