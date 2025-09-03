import SwiftUI
import SwiftData
import RealityKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [StickyNote]
    @State private var searchText = ""
    @State private var showingAddNote = false
    @State private var show3DView = false
    @State private var selectedCategory: Category?
    
    var filteredNotes: [StickyNote] {
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Search bar
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        // Notes grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredNotes) { note in
                                NoteCard(note: note)
                                    .contextMenu {
                                        Button("Edit") {
                                            // TODO: Edit functionality
                                        }
                                        Button("Delete", role: .destructive) {
                                            deleteNote(note)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .refreshable {
                    // Refresh functionality
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(action: {
                            showingAddNote = true
                        })
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Sticky Notes 3D")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        show3DView.toggle()
                    }) {
                        Image(systemName: "cube.transparent")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView()
        }
        .fullScreenCover(isPresented: $show3DView) {
            RealityView3D(notes: filteredNotes)
        }
    }
    
    private func deleteNote(_ note: StickyNote) {
        withAnimation {
            modelContext.delete(note)
        }
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var content = ""
    @State private var selectedColor = NoteColor.yellow
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Note Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Content", text: $content, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(5...10)
                }
                
                Section("Appearance") {
                    ColorPicker("Note Color", selection: Binding(
                        get: { selectedColor.color },
                        set: { newColor in
                            selectedColor = NoteColor.allCases.first { $0.color == newColor } ?? .yellow
                        }
                    ))
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        let newNote = StickyNote(
            title: title,
            content: content,
            color: selectedColor,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        modelContext.insert(newNote)
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StickyNote.self, inMemory: true)
}