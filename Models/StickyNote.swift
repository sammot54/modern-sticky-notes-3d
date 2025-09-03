import Foundation
import SwiftData
import SwiftUI

@Model
final class StickyNote {
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var color: NoteColor = .yellow
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var position: Position3D = Position3D()
    var category: Category?
    var tags: [String] = []
    var hasImage: Bool = false
    var imageData: Data?
    var priority: NotePriority = .normal
    var isDone: Bool = false
    
    init(title: String, content: String, color: NoteColor, createdAt: Date, updatedAt: Date) {
        self.title = title
        self.content = content
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum NoteColor: String, Codable, CaseIterable {
    case yellow = "yellow"
    case blue = "blue"
    case green = "green"
    case pink = "pink"
    case orange = "orange"
    case purple = "purple"
    case red = "red"
    case gray = "gray"
    
    var color: Color {
        switch self {
        case .yellow: return .yellow
        case .blue: return .blue
        case .green: return .green
        case .pink: return .pink
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        case .gray: return .gray
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum NotePriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return .secondary
        case .normal: return .primary
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

@Model
final class Position3D {
    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0
    
    init(x: Float = 0.0, y: Float = 0.0, z: Float = 0.0) {
        self.x = x
        self.y = y
        self.z = z
    }
}