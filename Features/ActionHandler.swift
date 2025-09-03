import Foundation
import EventKit
import MessageUI
import ContactsUI

@MainActor
final class ActionHandler: ObservableObject {
    private let eventStore = EKEventStore()
    
    // MARK: - Calendar Integration
    
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestWriteOnlyAccessToEvents()
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    func createCalendarEvent(from note: StickyNote, date: Date, duration: TimeInterval = 3600) async -> Bool {
        let hasAccess = await requestCalendarAccess()
        guard hasAccess else { return false }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = note.title
        event.notes = note.content
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Failed to save calendar event: \(error)")
            return false
        }
    }
    
    func createReminder(from note: StickyNote, date: Date) async -> Bool {
        let hasAccess = await requestCalendarAccess()
        guard hasAccess else { return false }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = note.title
        reminder.notes = note.content
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        let alarm = EKAlarm(absoluteDate: date)
        reminder.addAlarm(alarm)
        
        do {
            try eventStore.save(reminder, commit: true)
            return true
        } catch {
            print("Failed to save reminder: \(error)")
            return false
        }
    }
    
    // MARK: - Phone Actions
    
    func makePhoneCall(_ phoneNumber: String) {
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if let url = URL(string: "tel://\(cleanedNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func sendSMS(to phoneNumber: String, message: String) {
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "sms:\(cleanedNumber)?body=\(encodedMessage)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Email Actions
    
    func composeEmail(to emailAddress: String, subject: String, body: String) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:\(emailAddress)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - URL Actions
    
    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // MARK: - Smart Actions from Note Content
    
    func getAvailableActions(for note: StickyNote) -> [SmartAction] {
        var actions: [SmartAction] = []
        let analysis = SmartDetector().analyzeContent(note.title + " " + note.content)
        
        // Phone actions
        for phoneNumber in analysis.phoneNumbers {
            actions.append(SmartAction(
                type: .phone,
                title: "Call \(phoneNumber)",
                subtitle: "Make a phone call",
                iconName: "phone.fill",
                data: phoneNumber,
                action: { [weak self] in
                    self?.makePhoneCall(phoneNumber)
                }
            ))
            
            actions.append(SmartAction(
                type: .message,
                title: "Text \(phoneNumber)",
                subtitle: "Send SMS message",
                iconName: "message.fill",
                data: phoneNumber,
                action: { [weak self] in
                    self?.sendSMS(to: phoneNumber, message: note.content)
                }
            ))
        }
        
        // Email actions
        for emailAddress in analysis.emailAddresses {
            actions.append(SmartAction(
                type: .email,
                title: "Email \(emailAddress)",
                subtitle: "Compose email",
                iconName: "envelope.fill",
                data: emailAddress,
                action: { [weak self] in
                    self?.composeEmail(to: emailAddress, subject: note.title, body: note.content)
                }
            ))
        }
        
        // URL actions
        for url in analysis.urls {
            actions.append(SmartAction(
                type: .web,
                title: "Open Link",
                subtitle: url,
                iconName: "link",
                data: url,
                action: { [weak self] in
                    self?.openURL(url)
                }
            ))
        }
        
        // Calendar actions
        for date in analysis.dates {
            actions.append(SmartAction(
                type: .calendar,
                title: "Add to Calendar",
                subtitle: date.formatted(.dateTime),
                iconName: "calendar.badge.plus",
                data: date,
                action: { [weak self] in
                    Task {
                        await self?.createCalendarEvent(from: note, date: date)
                    }
                }
            ))
            
            actions.append(SmartAction(
                type: .reminder,
                title: "Set Reminder",
                subtitle: date.formatted(.dateTime),
                iconName: "bell.badge.fill",
                data: date,
                action: { [weak self] in
                    Task {
                        await self?.createReminder(from: note, date: date)
                    }
                }
            ))
        }
        
        return actions
    }
    
    // MARK: - Share Actions
    
    func shareNote(_ note: StickyNote, from sourceView: UIView) {
        let shareText = "\(note.title)\n\n\(note.content)"
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        // Present from the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
    
    func exportNoteAsText(_ note: StickyNote) -> URL? {
        let fileName = "\(note.title.replacingOccurrences(of: " ", with: "_")).txt"
        let content = "\(note.title)\n\n\(note.content)\n\nCreated: \(note.createdAt.formatted(.dateTime))"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export note: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

struct SmartAction {
    let type: ActionType
    let title: String
    let subtitle: String
    let iconName: String
    let data: Any
    let action: () -> Void
}

enum ActionType: String, CaseIterable {
    case phone = "phone"
    case message = "message"
    case email = "email"
    case web = "web"
    case calendar = "calendar"
    case reminder = "reminder"
    case share = "share"
    case export = "export"
    
    var displayName: String {
        switch self {
        case .phone: return "Phone"
        case .message: return "Message"
        case .email: return "Email"
        case .web: return "Web"
        case .calendar: return "Calendar"
        case .reminder: return "Reminder"
        case .share: return "Share"
        case .export: return "Export"
        }
    }
    
    var color: Color {
        switch self {
        case .phone: return .green
        case .message: return .blue
        case .email: return .red
        case .web: return .purple
        case .calendar: return .orange
        case .reminder: return .yellow
        case .share: return .indigo
        case .export: return .teal
        }
    }
}

// MARK: - SwiftUI Integration

struct ActionButton: View {
    let action: SmartAction
    
    var body: some View {
        Button(action: action.action) {
            HStack {
                Image(systemName: action.iconName)
                    .font(.title3)
                    .foregroundColor(action.type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(action.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SmartActionsView: View {
    let note: StickyNote
    @StateObject private var actionHandler = ActionHandler()
    
    var body: some View {
        let actions = actionHandler.getAvailableActions(for: note)
        
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Smart Actions")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 8) {
                    ForEach(actions.indices, id: \.self) { index in
                        ActionButton(action: actions[index])
                    }
                }
                .padding(.horizontal)
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    let sampleNote = StickyNote(
        title: "Call John at 555-123-4567",
        content: "Don't forget to call John tomorrow at 2 PM. Email him at john@example.com if he doesn't answer. Check https://example.com for details.",
        color: .yellow,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    return SmartActionsView(note: sampleNote)
        .padding()
}