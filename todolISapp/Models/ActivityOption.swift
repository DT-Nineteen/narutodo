//
//  ActivityOption.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import Foundation

// MARK: - Activity Option Model
struct ActivityOption: Identifiable, Codable, Equatable {
    let id = UUID() // Unique identifier for each activity option
    let title: String
    let emoji: String
    let description: String?
    
    init(title: String, emoji: String, description: String? = nil) {
        self.title = title
        self.emoji = emoji
        self.description = description
    }       
    
    // MARK: - Equatable Implementation
    static func == (lhs: ActivityOption, rhs: ActivityOption) -> Bool {
        return lhs.id == rhs.id && 
               lhs.title == rhs.title && 
               lhs.emoji == rhs.emoji && 
               lhs.description == rhs.description
    }
}

// MARK: - Activity Category Enum
enum ActivityCategory: String, CaseIterable {
    case whereToGo = "Đi đâu"
    case whatToDo = "Chơi gì" 
    case whatToEat = "Ăn gì"
    
    var emoji: String {
        switch self {
        case .whereToGo: return "📍"
        case .whatToDo: return "🎮"
        case .whatToEat: return "🍜"
        }
    }
}

// MARK: - Random Activity Result
struct RandomActivity {
    let whereToGo: ActivityOption
    let whatToDo: ActivityOption
    let whatToEat: ActivityOption
    let generatedAt: Date
    
    init(whereToGo: ActivityOption, whatToDo: ActivityOption, whatToEat: ActivityOption) {
        self.whereToGo = whereToGo
        self.whatToDo = whatToDo
        self.whatToEat = whatToEat
        self.generatedAt = Date()
    }
}

// MARK: - Hardcoded Data - Dattebayo!
struct ActivityData {
    static let whereToGoOptions: [ActivityOption] = [
        ActivityOption(title: "Công viên Thống Nhất", emoji: "🌳", description: "Đi dạo và thư giãn"),
        ActivityOption(title: "Hồ Gươm", emoji: "🏞️", description: "Ngắm cảnh và chụp ảnh"),
        ActivityOption(title: "Phố cổ Hà Nội", emoji: "🏛️", description: "Khám phá văn hóa"),
        ActivityOption(title: "Times City", emoji: "🏢", description: "Shopping và giải trí"),
        ActivityOption(title: "Lotte Center", emoji: "🌆", description: "Ngắm toàn cảnh thành phố"),
        ActivityOption(title: "Café đường tàu", emoji: "☕", description: "Uống cà phê unique"),
        ActivityOption(title: "Chợ đêm", emoji: "🌙", description: "Ăn vặt và mua sắm"),
        ActivityOption(title: "Công viên Thủ Lệ", emoji: "🎡", description: "Vui chơi và thư giãn")
    ]
    
    static let whatToDoOptions: [ActivityOption] = [
        ActivityOption(title: "Xem phim", emoji: "🎬", description: "Thư giãn và giải trí"),
        ActivityOption(title: "Karaoke", emoji: "🎤", description: "Hát và vui vẻ"),
        ActivityOption(title: "Chụp ảnh", emoji: "📸", description: "Lưu lại kỷ niệm"),
        ActivityOption(title: "Đọc sách", emoji: "📚", description: "Học hỏi kiến thức mới"),
        ActivityOption(title: "Chơi game", emoji: "🎮", description: "Giải trí điện tử"),
        ActivityOption(title: "Tập thể dục", emoji: "💪", description: "Rèn luyện sức khỏe"),
        ActivityOption(title: "Nghe nhạc", emoji: "🎵", description: "Thư giãn và cảm xúc"),
        ActivityOption(title: "Vẽ tranh", emoji: "🎨", description: "Sáng tạo nghệ thuật")
    ]
    
    static let whatToEatOptions: [ActivityOption] = [
        ActivityOption(title: "Phở", emoji: "🍜", description: "Món quốc hồn quốc túy"),
        ActivityOption(title: "Bún chả", emoji: "🥢", description: "Đặc sản Hà Nội"),
        ActivityOption(title: "Bánh mì", emoji: "🥖", description: "Nhanh gọn và ngon"),
        ActivityOption(title: "Chả cá", emoji: "🐟", description: "Món truyền thống"),
        ActivityOption(title: "Nem rán", emoji: "🥟", description: "Giòn tan thơm ngon"),
        ActivityOption(title: "Trà sữa", emoji: "🧋", description: "Đồ uống trendy"),
        ActivityOption(title: "Kem", emoji: "🍦", description: "Mát lạnh ngọt ngào"),
        ActivityOption(title: "Lẩu", emoji: "🍲", description: "Ăn cùng bạn bè")
    ]
} 