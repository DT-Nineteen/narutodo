import Foundation

struct Profile: Codable, Identifiable {
  let id: UUID
  var email: String?
  var fullName: String?
  var avatarUrl: String?
  var updatedAt: Date?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case email
    case fullName = "full_name"
    case avatarUrl = "avatar_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
