import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var color: Color = .blue
    var iconName: String = "folder"
    var createdAt: Date = Date()
    var notes: [StickyNote] = []
    
    init(name: String, color: Color, iconName: String) {
        self.name = name
        self.color = color
        self.iconName = iconName
        self.createdAt = Date()
    }
}

extension Category {
    static let defaultCategories: [Category] = [
        Category(name: "Personal", color: .blue, iconName: "person.fill"),
        Category(name: "Work", color: .orange, iconName: "briefcase.fill"),
        Category(name: "Ideas", color: .purple, iconName: "lightbulb.fill"),
        Category(name: "Shopping", color: .green, iconName: "cart.fill"),
        Category(name: "Important", color: .red, iconName: "exclamationmark.triangle.fill")
    ]
}