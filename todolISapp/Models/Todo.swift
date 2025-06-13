import Foundation

struct Todo: Codable, Identifiable, Hashable {
  let id: UUID
  var title: String
  var isCompleted: Bool
  let createdAt: Date
  var dueDate: Date?
  var activityId: UUID?

  enum CodingKeys: String, CodingKey {
    case id, title
    case isCompleted = "is_completed"
    case createdAt = "created_at"
    case dueDate = "due_date"
    case activityId = "activity_id"
  }

  // Custom initializer for decoding
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Decode simple properties
    id = try container.decode(UUID.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
    activityId = try container.decodeIfPresent(UUID.self, forKey: .activityId)

    // Handle createdAt date
    let createdAtString = try container.decode(String.self, forKey: .createdAt)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS+00:00"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    if let date = formatter.date(from: createdAtString) {
      createdAt = date
    } else {
      // Fallback for different timestamp formats
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+00:00"
      createdAt = formatter.date(from: createdAtString) ?? Date()
    }

    // Handle dueDate - this is the main fix for the error
    if let dueDateString = try container.decodeIfPresent(String.self, forKey: .dueDate) {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"  // Handle the specific format causing the error
      dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
      dueDate = dateFormatter.date(from: dueDateString)
    } else {
      dueDate = nil
    }

    print("[DEBUG] Successfully decoded todo: \(title), dueDate: \(dueDate?.description ?? "nil")")
  }

  // Custom encoding
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    // Encode simple properties
    try container.encode(id, forKey: .id)
    try container.encode(title, forKey: .title)
    try container.encode(isCompleted, forKey: .isCompleted)
    try container.encodeIfPresent(activityId, forKey: .activityId)

    // Custom date encoding - use ISO format for consistency
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS+00:00"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    // For dueDate, we'll send just the date part since it's date-only
    let dateOnlyFormatter = DateFormatter()
    dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
    dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    // Encode createdAt
    let createdAtString = dateFormatter.string(from: createdAt)
    try container.encode(createdAtString, forKey: .createdAt)

    // Encode dueDate (date only format)
    if let dueDate = dueDate {
      let dueDateString = dateOnlyFormatter.string(from: dueDate)
      try container.encode(dueDateString, forKey: .dueDate)
      print("[DEBUG] Encoding dueDate as: \(dueDateString)")
    }
  }

  // Regular initializer for creating new todos
  init(
    id: UUID, title: String, isCompleted: Bool, createdAt: Date, dueDate: Date? = nil,
    activityId: UUID? = nil
  ) {
    self.id = id
    self.title = title
    self.isCompleted = isCompleted
    self.createdAt = createdAt
    self.dueDate = dueDate
    self.activityId = activityId
  }
}
