import Foundation
import RealityKit
import simd

@MainActor
final class SpatialEngine: ObservableObject {
    private var notePositions: [UUID: SIMD3<Float>] = [:]
    private let maxRadius: Float = 2.0
    private let minDistance: Float = 0.2
    
    // MARK: - Position Management
    
    func getPosition(for note: StickyNote) -> SIMD3<Float> {
        if let existingPosition = notePositions[note.id] {
            return existingPosition
        }
        
        let position = generateRandomPosition()
        notePositions[note.id] = position
        return position
    }
    
    func setPosition(for note: StickyNote, position: SIMD3<Float>) {
        notePositions[note.id] = position
    }
    
    func resetPositions() {
        notePositions.removeAll()
    }
    
    // MARK: - Clustering Algorithms
    
    func clusterByCategory(notes: [StickyNote]) {
        let categories = Array(Set(notes.compactMap { $0.category?.name }))
        let uncategorizedNotes = notes.filter { $0.category == nil }
        
        var categoryIndex = 0
        for category in categories {
            let categoryNotes = notes.filter { $0.category?.name == category }
            positionNotesInCluster(
                notes: categoryNotes,
                centerPosition: getClusterCenter(for: categoryIndex, totalClusters: categories.count + (uncategorizedNotes.isEmpty ? 0 : 1)),
                radius: 0.5
            )
            categoryIndex += 1
        }
        
        // Position uncategorized notes
        if !uncategorizedNotes.isEmpty {
            positionNotesInCluster(
                notes: uncategorizedNotes,
                centerPosition: getClusterCenter(for: categoryIndex, totalClusters: categories.count + 1),
                radius: 0.5
            )
        }
    }
    
    func clusterByDate(notes: [StickyNote]) {
        let calendar = Calendar.current
        let now = Date()
        
        // Group by time periods
        let today = notes.filter { calendar.isDateInToday($0.createdAt) }
        let yesterday = notes.filter { calendar.isDateInYesterday($0.createdAt) }
        let thisWeek = notes.filter { 
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return $0.createdAt >= weekAgo && !calendar.isDateInToday($0.createdAt) && !calendar.isDateInYesterday($0.createdAt)
        }
        let thisMonth = notes.filter {
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return $0.createdAt >= monthAgo && $0.createdAt < calendar.date(byAdding: .day, value: -7, to: now)!
        }
        let older = notes.filter {
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return $0.createdAt < monthAgo
        }
        
        let groups = [
            ("Today", today),
            ("Yesterday", yesterday),
            ("This Week", thisWeek),
            ("This Month", thisMonth),
            ("Older", older)
        ].filter { !$1.isEmpty }
        
        for (index, (_, groupNotes)) in groups.enumerated() {
            positionNotesInCluster(
                notes: groupNotes,
                centerPosition: getClusterCenter(for: index, totalClusters: groups.count),
                radius: 0.4
            )
        }
    }
    
    func clusterByPriority(notes: [StickyNote]) {
        let priorities = NotePriority.allCases
        
        for (index, priority) in priorities.enumerated() {
            let priorityNotes = notes.filter { $0.priority == priority }
            if !priorityNotes.isEmpty {
                positionNotesInCluster(
                    notes: priorityNotes,
                    centerPosition: getClusterCenter(for: index, totalClusters: priorities.count),
                    radius: 0.4
                )
            }
        }
    }
    
    func scatterRandomly(notes: [StickyNote]) {
        for note in notes {
            let position = generateRandomPosition()
            notePositions[note.id] = position
        }
    }
    
    func arrangeInGrid(notes: [StickyNote]) {
        let columns = Int(ceil(sqrt(Double(notes.count))))
        let spacing: Float = 0.2
        
        for (index, note) in notes.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let x = Float(col - columns/2) * spacing
            let y = Float(row - notes.count/(columns * 2)) * spacing
            let z = Float.random(in: -0.1...0.1)
            
            notePositions[note.id] = SIMD3(x, y, z)
        }
    }
    
    func arrangeInSpiral(notes: [StickyNote]) {
        let goldenAngle = Float.pi * (3.0 - sqrt(5.0)) // Golden angle in radians
        
        for (index, note) in notes.enumerated() {
            let theta = Float(index) * goldenAngle
            let radius = sqrt(Float(index)) * 0.1
            
            let x = radius * cos(theta)
            let y = radius * sin(theta)
            let z = Float.random(in: -0.2...0.2)
            
            notePositions[note.id] = SIMD3(x, y, z)
        }
    }
    
    // MARK: - Private Helpers
    
    private func generateRandomPosition() -> SIMD3<Float> {
        let angle = Float.random(in: 0...(2 * .pi))
        let radius = Float.random(in: 0.2...maxRadius)
        let height = Float.random(in: -0.5...0.5)
        
        let x = radius * cos(angle)
        let y = height
        let z = radius * sin(angle)
        
        return SIMD3(x, y, z)
    }
    
    private func getClusterCenter(for index: Int, totalClusters: Int) -> SIMD3<Float> {
        let angle = (Float(index) / Float(totalClusters)) * 2 * .pi
        let radius: Float = 1.0
        
        let x = radius * cos(angle)
        let z = radius * sin(angle)
        let y: Float = 0
        
        return SIMD3(x, y, z)
    }
    
    private func positionNotesInCluster(notes: [StickyNote], centerPosition: SIMD3<Float>, radius: Float) {
        if notes.count == 1 {
            notePositions[notes.first!.id] = centerPosition
            return
        }
        
        for (index, note) in notes.enumerated() {
            let angle = (Float(index) / Float(notes.count)) * 2 * .pi
            let clusterRadius = radius * sqrt(Float(notes.count)) / 5.0
            
            let x = centerPosition.x + clusterRadius * cos(angle)
            let y = centerPosition.y + Float.random(in: -0.1...0.1)
            let z = centerPosition.z + clusterRadius * sin(angle)
            
            notePositions[note.id] = SIMD3(x, y, z)
        }
    }
    
    // MARK: - Physics Simulation
    
    func applyPhysicsSimulation(notes: [StickyNote]) {
        // Simple force-based layout to prevent overlapping
        for _ in 0..<10 { // Multiple iterations for stability
            for note1 in notes {
                guard let pos1 = notePositions[note1.id] else { continue }
                var force = SIMD3<Float>(0, 0, 0)
                
                // Repulsion from other notes
                for note2 in notes {
                    guard note1.id != note2.id, let pos2 = notePositions[note2.id] else { continue }
                    
                    let diff = pos1 - pos2
                    let distance = length(diff)
                    
                    if distance < minDistance && distance > 0 {
                        let repulsionForce = normalize(diff) * (minDistance - distance) * 0.1
                        force += repulsionForce
                    }
                }
                
                // Apply force
                let newPosition = pos1 + force
                notePositions[note1.id] = newPosition
            }
        }
    }
    
    // MARK: - Animation Helpers
    
    func animateToNewPositions(notes: [StickyNote], duration: TimeInterval = 1.0) {
        // This would be used to smoothly animate notes to new positions
        // The actual animation would be handled by RealityKit
        for note in notes {
            // Trigger position update animation
            objectWillChange.send()
        }
    }
    
    // MARK: - Utility Functions
    
    func getDistanceBetween(note1: StickyNote, note2: StickyNote) -> Float {
        guard let pos1 = notePositions[note1.id],
              let pos2 = notePositions[note2.id] else {
            return Float.infinity
        }
        
        return distance(pos1, pos2)
    }
    
    func getNearestNotes(to note: StickyNote, from notes: [StickyNote], count: Int = 5) -> [StickyNote] {
        guard let targetPosition = notePositions[note.id] else { return [] }
        
        return notes
            .filter { $0.id != note.id }
            .compactMap { otherNote -> (StickyNote, Float)? in
                guard let position = notePositions[otherNote.id] else { return nil }
                let dist = distance(targetPosition, position)
                return (otherNote, dist)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(count)
            .map { $0.0 }
    }
    
    func getBoundingBox(for notes: [StickyNote]) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        let positions = notes.compactMap { notePositions[$0.id] }
        guard !positions.isEmpty else {
            return (min: SIMD3<Float>(0, 0, 0), max: SIMD3<Float>(0, 0, 0))
        }
        
        let minX = positions.map { $0.x }.min() ?? 0
        let minY = positions.map { $0.y }.min() ?? 0
        let minZ = positions.map { $0.z }.min() ?? 0
        
        let maxX = positions.map { $0.x }.max() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0
        let maxZ = positions.map { $0.z }.max() ?? 0
        
        return (
            min: SIMD3<Float>(minX, minY, minZ),
            max: SIMD3<Float>(maxX, maxY, maxZ)
        )
    }
}