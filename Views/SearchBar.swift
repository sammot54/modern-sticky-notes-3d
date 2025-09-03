import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .padding(.leading, 12)
                
                TextField("Search notes...", text: $text)
                    .focused($isFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        isEditing = true
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            if isEditing {
                Button("Cancel") {
                    text = ""
                    isEditing = false
                    isFocused = false
                }
                .foregroundColor(.accentColor)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .onAppear {
            isEditing = !text.isEmpty
        }
    }
}

struct SearchBarWithFilters: View {
    @Binding var searchText: String
    @Binding var selectedCategory: Category?
    let categories: [Category]
    @State private var showingFilters = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                SearchBar(text: $searchText)
                
                Button(action: {
                    showingFilters.toggle()
                }) {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            if showingFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All categories button
                        FilterButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: {
                                selectedCategory = nil
                            }
                        )
                        
                        // Category filters
                        ForEach(categories, id: \.id) { category in
                            FilterButton(
                                title: category.name,
                                icon: category.iconName,
                                color: category.color,
                                isSelected: selectedCategory?.id == category.id,
                                action: {
                                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingFilters)
    }
}

struct FilterButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? color : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBar(text: .constant(""))
        
        SearchBar(text: .constant("Sample search"))
        
        SearchBarWithFilters(
            searchText: .constant(""),
            selectedCategory: .constant(nil),
            categories: Category.defaultCategories
        )
    }
    .padding()
}