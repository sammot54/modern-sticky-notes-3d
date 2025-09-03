import Foundation
import SwiftData
import SwiftUI

@MainActor
final class NoteStore: ObservableObject {
    private var modelContext: ModelContext
    
    @Published var notes: [StickyNote] = []
    @Published var categories: [Category] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Category?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    func loadData() {
        do {
            let noteDescriptor = FetchDescriptor<StickyNote>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            notes = try modelContext.fetch(noteDescriptor)
            
            let categoryDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
            categories = try modelContext.fetch(categoryDescriptor)
            
            // Create default categories if none exist
            if categories.isEmpty {
                createDefaultCategories()
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    
    func createNote(title: String, content: String, color: NoteColor, category: Category? = nil) {
        let note = StickyNote(
            title: title,
            content: content,
            color: color,
            createdAt: Date(),
            updatedAt: Date()
        )
        note.category = category
        
        modelContext.insert(note)
        saveContext()
        loadData()
    }
    
    func updateNote(_ note: StickyNote) {
        note.updatedAt = Date()
        saveContext()
        loadData()
    }
    
    func deleteNote(_ note: StickyNote) {
        modelContext.delete(note)
        saveContext()
        loadData()
    }
    
    func createCategory(name: String, color: Color, iconName: String) {
        let category = Category(name: name, color: color, iconName: iconName)
        modelContext.insert(category)
        saveContext()
        loadData()
    }
    
    func deleteCategory(_ category: Category) {
        // Remove category from all notes
        for note in category.notes {
            note.category = nil
        }
        
        modelContext.delete(category)
        saveContext()
        loadData()
    }
    
    private func createDefaultCategories() {
        for categoryData in Category.defaultCategories {
            modelContext.insert(categoryData)
        }
        saveContext()
        loadData()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - Search and Filter
    
    func filteredNotes() -> [StickyNote] {
        var filtered = notes
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category?.id == selectedCategory.id }
        }
        
        return filtered
    }
    
    // MARK: - Smart Features
    
    func smartCategorizeNote(_ note: StickyNote) {
        // Simple keyword-based categorization
        let content = (note.title + " " + note.content).lowercased()
        
        if content.contains("work") || content.contains("meeting") || content.contains("project") {
            note.category = categories.first { $0.name == "Work" }
        } else if content.contains("buy") || content.contains("shop") || content.contains("grocery") {
            note.category = categories.first { $0.name == "Shopping" }
        } else if content.contains("idea") || content.contains("thought") || content.contains("inspiration") {
            note.category = categories.first { $0.name == "Ideas" }
        } else if content.contains("urgent") || content.contains("important") || content.contains("asap") {
            note.category = categories.first { $0.name == "Important" }
        } else {
            note.category = categories.first { $0.name == "Personal" }
        }
        
        updateNote(note)
    }
}