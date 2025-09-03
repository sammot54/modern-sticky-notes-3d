import SwiftUI

struct NoteCard: View {
    let note: StickyNote
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with category and priority
            HStack {
                if let category = note.category {
                    Label(category.name, systemImage: category.iconName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if note.priority != .normal {
                    Circle()
                        .fill(note.priority.color)
                        .frame(width: 8, height: 8)
                }
                
                if note.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Title
            Text(note.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Content
            Text(note.content)
                .font(.body)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .foregroundColor(.secondary)
            
            // Tags
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            Spacer(minLength: 0)
            
            // Footer
            HStack {
                Text(note.updatedAt.formatted(.dateTime.day().month().hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.tertiary)
                
                Spacer()
                
                if note.hasImage {
                    Image(systemName: "photo.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(note.color.color.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(note.color.color.opacity(0.6), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .shadow(
            color: note.color.color.opacity(0.3),
            radius: isPressed ? 2 : 8,
            x: 0,
            y: isPressed ? 1 : 4
        )
        .onTapGesture {
            // Handle tap
        }
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        } perform: {
            // Handle long press
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(note.title). \(note.content)")
        .accessibilityHint("Double tap to edit note")
    }
}

#Preview {
    let sampleNote = StickyNote(
        title: "Sample Note",
        content: "This is a sample note with some content to demonstrate the card layout.",
        color: .yellow,
        createdAt: Date(),
        updatedAt: Date()
    )
    sampleNote.tags = ["sample", "demo"]
    sampleNote.priority = .high
    
    return NoteCard(note: sampleNote)
        .padding()
        .frame(width: 200)
}