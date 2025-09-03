import RealityKit
import SwiftUI
import Foundation

@MainActor
final class Note3DEntity: Entity {
    
    static func create(from note: StickyNote) async -> Entity {
        let entity = Entity()
        entity.name = "note_\(note.id.uuidString)"
        
        // Create the note mesh (a rounded rectangle)
        let mesh = try! MeshResource.generateBox(
            size: SIMD3(0.1, 0.15, 0.01),
            cornerRadius: 0.005
        )
        
        // Create material based on note color
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor(note.color.color))
        material.roughness = .init(floatLiteral: 0.3)
        material.metallic = .init(floatLiteral: 0.1)
        
        // Add the model component
        entity.components.set(ModelComponent(
            mesh: mesh,
            materials: [material]
        ))
        
        // Add text overlay
        await addTextOverlay(to: entity, note: note)
        
        // Add animation
        addFloatingAnimation(to: entity)
        
        return entity
    }
    
    static func update(entity: Entity, with note: StickyNote) async {
        // Update the material color
        if var modelComponent = entity.components[ModelComponent.self] {
            var material = SimpleMaterial()
            material.color = .init(tint: UIColor(note.color.color))
            material.roughness = .init(floatLiteral: 0.3)
            material.metallic = .init(floatLiteral: 0.1)
            
            modelComponent.materials = [material]
            entity.components.set(modelComponent)
        }
        
        // Update text overlay
        if let textEntity = entity.children.first(where: { $0.name == "text_overlay" }) {
            entity.removeChild(textEntity)
        }
        await addTextOverlay(to: entity, note: note)
    }
    
    private static func addTextOverlay(to entity: Entity, note: StickyNote) async {
        // Create text entity
        let textEntity = Entity()
        textEntity.name = "text_overlay"
        
        // Create text mesh
        let textMesh = try! MeshResource.generateText(
            note.title.count > 20 ? String(note.title.prefix(17)) + "..." : note.title,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.01, weight: .semibold),
            containerFrame: CGRect(x: 0, y: 0, width: 0.08, height: 0.02),
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        
        // Create text material
        var textMaterial = SimpleMaterial()
        textMaterial.color = .init(tint: .black)
        
        // Add text model component
        textEntity.components.set(ModelComponent(
            mesh: textMesh,
            materials: [textMaterial]
        ))
        
        // Position text on the note
        textEntity.position = SIMD3(0, 0.05, 0.006)
        
        entity.addChild(textEntity)
        
        // Add subtitle text if content exists
        if !note.content.isEmpty {
            let subtitleEntity = Entity()
            subtitleEntity.name = "subtitle_overlay"
            
            let subtitleText = note.content.count > 30 ? String(note.content.prefix(27)) + "..." : note.content
            let subtitleMesh = try! MeshResource.generateText(
                subtitleText,
                extrusionDepth: 0.0005,
                font: .systemFont(ofSize: 0.006, weight: .regular),
                containerFrame: CGRect(x: 0, y: 0, width: 0.08, height: 0.04),
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            
            var subtitleMaterial = SimpleMaterial()
            subtitleMaterial.color = .init(tint: UIColor.darkGray)
            
            subtitleEntity.components.set(ModelComponent(
                mesh: subtitleMesh,
                materials: [subtitleMaterial]
            ))
            
            subtitleEntity.position = SIMD3(0, 0.02, 0.006)
            entity.addChild(subtitleEntity)
        }
        
        // Add category indicator
        if let category = note.category {
            let indicatorEntity = Entity()
            indicatorEntity.name = "category_indicator"
            
            // Create a small sphere for category
            let indicatorMesh = try! MeshResource.generateSphere(radius: 0.003)
            var indicatorMaterial = SimpleMaterial()
            indicatorMaterial.color = .init(tint: UIColor(category.color))
            
            indicatorEntity.components.set(ModelComponent(
                mesh: indicatorMesh,
                materials: [indicatorMaterial]
            ))
            
            indicatorEntity.position = SIMD3(0.04, 0.065, 0.006)
            entity.addChild(indicatorEntity)
        }
        
        // Add priority indicator
        if note.priority != .normal {
            let priorityEntity = Entity()
            priorityEntity.name = "priority_indicator"
            
            let priorityMesh = try! MeshResource.generateSphere(radius: 0.002)
            var priorityMaterial = SimpleMaterial()
            priorityMaterial.color = .init(tint: UIColor(note.priority.color))
            
            priorityEntity.components.set(ModelComponent(
                mesh: priorityMesh,
                materials: [priorityMaterial]
            ))
            
            priorityEntity.position = SIMD3(-0.04, 0.065, 0.006)
            entity.addChild(priorityEntity)
        }
    }
    
    private static func addFloatingAnimation(to entity: Entity) {
        // Create subtle floating animation
        let floatUp = Transform(
            scale: SIMD3(repeating: 1.0),
            rotation: simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)),
            translation: SIMD3(0, 0.005, 0)
        )
        
        let floatDown = Transform(
            scale: SIMD3(repeating: 1.0),
            rotation: simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)),
            translation: SIMD3(0, -0.005, 0)
        )
        
        let floatingAnimation = FromToByAnimation(
            name: "floating",
            from: floatDown,
            to: floatUp,
            duration: 2.0,
            timing: .easeInOut,
            isAdditive: true,
            repeatMode: .pingPong,
            fillMode: .both
        )
        
        if let animationResource = try? AnimationResource.generate(with: floatingAnimation) {
            entity.playAnimation(animationResource, startsPaused: false)
        }
    }
    
    // MARK: - Interaction Methods
    
    static func addHoverEffect(to entity: Entity) {
        let scaleUp = Transform(
            scale: SIMD3(repeating: 1.1),
            rotation: simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)),
            translation: SIMD3(0, 0, 0)
        )
        
        let hoverAnimation = FromToByAnimation(
            name: "hover",
            from: .identity,
            to: scaleUp,
            duration: 0.2,
            timing: .easeOut,
            isAdditive: false,
            repeatMode: .none,
            fillMode: .forwards
        )
        
        if let animationResource = try? AnimationResource.generate(with: hoverAnimation) {
            entity.playAnimation(animationResource, startsPaused: false)
        }
    }
    
    static func removeHoverEffect(from entity: Entity) {
        let scaleNormal = Transform(
            scale: SIMD3(repeating: 1.0),
            rotation: simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)),
            translation: SIMD3(0, 0, 0)
        )
        
        let normalAnimation = FromToByAnimation(
            name: "normal",
            from: Transform(scale: SIMD3(repeating: 1.1)),
            to: scaleNormal,
            duration: 0.2,
            timing: .easeOut,
            isAdditive: false,
            repeatMode: .none,
            fillMode: .forwards
        )
        
        if let animationResource = try? AnimationResource.generate(with: normalAnimation) {
            entity.playAnimation(animationResource, startsPaused: false)
        }
    }
    
    static func addSelectionGlow(to entity: Entity) {
        // Add a glowing outline effect for selected notes
        let glowEntity = Entity()
        glowEntity.name = "glow_effect"
        
        let glowMesh = try! MeshResource.generateBox(
            size: SIMD3(0.11, 0.16, 0.02),
            cornerRadius: 0.005
        )
        
        var glowMaterial = SimpleMaterial()
        glowMaterial.color = .init(tint: .systemBlue)
        glowMaterial.roughness = .init(floatLiteral: 0.0)
        glowMaterial.metallic = .init(floatLiteral: 1.0)
        
        glowEntity.components.set(ModelComponent(
            mesh: glowMesh,
            materials: [glowMaterial]
        ))
        
        glowEntity.position = SIMD3(0, 0, -0.001)
        entity.addChild(glowEntity)
    }
    
    static func removeSelectionGlow(from entity: Entity) {
        if let glowEntity = entity.children.first(where: { $0.name == "glow_effect" }) {
            entity.removeChild(glowEntity)
        }
    }
}