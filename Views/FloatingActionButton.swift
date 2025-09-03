import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.3),
                            radius: isPressed ? 4 : 12,
                            x: 0,
                            y: isPressed ? 2 : 6
                        )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        } perform: {
            // Handle long press if needed
        }
        .accessibilityLabel("Add new note")
        .accessibilityHint("Tap to create a new sticky note")
    }
}

struct ExpandableFloatingActionButton: View {
    @State private var isExpanded = false
    @State private var isPressed = false
    
    let actions: [(icon: String, title: String, color: Color, action: () -> Void)]
    
    var body: some View {
        VStack(spacing: 16) {
            // Secondary action buttons (shown when expanded)
            if isExpanded {
                ForEach(actions.reversed(), id: \.title) { actionItem in
                    SecondaryFAB(
                        icon: actionItem.icon,
                        title: actionItem.title,
                        color: actionItem.color,
                        action: {
                            actionItem.action()
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Main FAB
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: .black.opacity(0.3),
                                radius: isPressed ? 4 : 12,
                                x: 0,
                                y: isPressed ? 2 : 6
                            )
                    )
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0) { isPressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = isPressing
                }
            } perform: {}
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isExpanded ? "Close menu" : "Add new note")
    }
}

struct SecondaryFAB: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            // Label
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            
            // Button
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color)
                            .shadow(
                                color: .black.opacity(0.2),
                                radius: isPressed ? 2 : 8,
                                x: 0,
                                y: isPressed ? 1 : 4
                            )
                    )
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0) { isPressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = isPressing
                }
            } perform: {}
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        FloatingActionButton(action: {
            print("Add note tapped")
        })
        
        ExpandableFloatingActionButton(actions: [
            (icon: "camera.fill", title: "Scan", color: .green, action: { print("Scan") }),
            (icon: "photo.fill", title: "Photo", color: .blue, action: { print("Photo") }),
            (icon: "mic.fill", title: "Voice", color: .red, action: { print("Voice") }),
            (icon: "pencil", title: "Write", color: .orange, action: { print("Write") })
        ])
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGray6))
}