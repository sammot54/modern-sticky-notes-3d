import SwiftUI
import RealityKit

struct RealityView3D: View {
    let notes: [StickyNote]
    @State private var spatialEngine = SpatialEngine()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNote: StickyNote?
    @State private var showingNoteDetail = false
    
    var body: some View {
        NavigationStack {
            RealityView { content in
                setupInitialScene(content: content)
                await createNoteEntities(content: content)
            } update: { content in
                await updateNoteEntities(content: content)
            }
            .gesture(
                TapGesture()
                    .onEnded { value in
                        // Handle tap on 3D space
                    }
            )
            .navigationTitle("3D Notes View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Reset View") {
                            spatialEngine.resetPositions()
                        }
                        Button("Cluster by Category") {
                            spatialEngine.clusterByCategory(notes: notes)
                        }
                        Button("Cluster by Date") {
                            spatialEngine.clusterByDate(notes: notes)
                        }
                        Button("Scatter Random") {
                            spatialEngine.scatterRandomly(notes: notes)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNoteDetail) {
            if let selectedNote = selectedNote {
                NoteDetailView(note: selectedNote)
            }
        }
    }
    
    private func setupInitialScene(content: RealityViewContent) {
        // Add lighting
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 1000
        directionalLight.light.isRealWorldProxy = true
        directionalLight.orientation = simd_quatf(angle: .pi / 4, axis: SIMD3(x: 1, y: -1, z: 0))
        
        let lightAnchor = AnchorEntity(.world(transform: .init()))
        lightAnchor.addChild(directionalLight)
        content.add(lightAnchor)
        
        // Add ambient light
        let ambientLight = Entity()
        ambientLight.components.set(DirectionalLightComponent(
            color: .white,
            intensity: 300,
            isRealWorldProxy: false
        ))
        content.add(ambientLight)
    }
    
    private func createNoteEntities(content: RealityViewContent) async {
        for note in notes {
            let noteEntity = await Note3DEntity.create(from: note)
            
            // Position based on spatial engine
            let position = spatialEngine.getPosition(for: note)
            noteEntity.position = position
            
            // Add tap gesture
            noteEntity.components.set(InputTargetComponent())
            noteEntity.components.set(CollisionComponent(
                shapes: [.generateBox(size: SIMD3(0.1, 0.15, 0.01))],
                isStatic: true
            ))
            
            content.add(noteEntity)
        }
    }
    
    private func updateNoteEntities(content: RealityViewContent) async {
        // Update existing entities or create new ones if needed
        for note in notes {
            if let existingEntity = content.entities.first(where: { entity in
                entity.name == "note_\(note.id.uuidString)"
            }) {
                // Update existing entity
                await Note3DEntity.update(entity: existingEntity, with: note)
            } else {
                // Create new entity
                let noteEntity = await Note3DEntity.create(from: note)
                let position = spatialEngine.getPosition(for: note)
                noteEntity.position = position
                content.add(noteEntity)
            }
        }
        
        // Remove entities for deleted notes
        let noteIds = Set(notes.map { $0.id.uuidString })
        content.entities.forEach { entity in
            if let name = entity.name,
               name.hasPrefix("note_"),
               !noteIds.contains(String(name.dropFirst(5))) {
                content.remove(entity)
            }
        }
    }
}

struct NoteDetailView: View {
    let note: StickyNote
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Note content
                    VStack(alignment: .leading, spacing: 12) {
                        Text(note.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(note.content)
                            .font(.body)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(note.color.color.opacity(0.2))
                    )
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
                        
                        Label("Created: \(note.createdAt.formatted(.dateTime))", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("Updated: \(note.updatedAt.formatted(.dateTime))", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let category = note.category {
                            Label(category.name, systemImage: category.iconName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Note Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let sampleNotes = [
        StickyNote(title: "Sample 1", content: "Content 1", color: .yellow, createdAt: Date(), updatedAt: Date()),
        StickyNote(title: "Sample 2", content: "Content 2", color: .blue, createdAt: Date(), updatedAt: Date()),
        StickyNote(title: "Sample 3", content: "Content 3", color: .green, createdAt: Date(), updatedAt: Date())
    ]
    
    return RealityView3D(notes: sampleNotes)
}