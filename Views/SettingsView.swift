import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useHapticFeedback") private var useHapticFeedback = true
    @AppStorage("defaultNoteColor") private var defaultNoteColorRaw = NoteColor.yellow.rawValue
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("showCreationDate") private var showCreationDate = false
    @AppStorage("gridColumns") private var gridColumns = 2
    @AppStorage("enable3DView") private var enable3DView = true
    
    private var defaultNoteColor: NoteColor {
        get { NoteColor(rawValue: defaultNoteColorRaw) ?? .yellow }
        set { defaultNoteColorRaw = newValue.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Appearance Section
                Section("Appearance") {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Theme")
                            Text("System default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Picker("Theme", selection: $isDarkMode) {
                            Text("Light").tag(false)
                            Text("Dark").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                    
                    HStack {
                        Image(systemName: "grid")
                            .foregroundColor(.green)
                        
                        Text("Grid Columns")
                        
                        Spacer()
                        
                        Stepper("\(gridColumns)", value: $gridColumns, in: 1...3)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                        
                        Toggle("Show Creation Date", isOn: $showCreationDate)
                    }
                }
                
                // Note Defaults Section
                Section("Note Defaults") {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.purple)
                        
                        Text("Default Color")
                        
                        Spacer()
                        
                        Menu {
                            ForEach(NoteColor.allCases, id: \.self) { color in
                                Button(action: {
                                    defaultNoteColorRaw = color.rawValue
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 16, height: 16)
                                        Text(color.displayName)
                                        if color == defaultNoteColor {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(defaultNoteColor.color)
                                    .frame(width: 20, height: 20)
                                Text(defaultNoteColor.displayName)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundColor(.blue)
                        
                        Toggle("Auto Save", isOn: $autoSave)
                    }
                }
                
                // Features Section
                Section("Features") {
                    HStack {
                        Image(systemName: "cube.transparent.fill")
                            .foregroundColor(.purple)
                        
                        Toggle("3D View", isOn: $enable3DView)
                    }
                    
                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(.green)
                        
                        Toggle("Haptic Feedback", isOn: $useHapticFeedback)
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.red)
                            Text("Notifications")
                        }
                    }
                }
                
                // Data & Privacy Section
                Section("Data & Privacy") {
                    NavigationLink(destination: DataExportView()) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.blue)
                            Text("Export Data")
                        }
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.purple)
                            Text("Privacy")
                        }
                    }
                    
                    Button(action: {
                        // Clear cache action
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear Cache")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Help & Support")
                        }
                    }
                    
                    NavigationLink(destination: AcknowledgementsView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Acknowledgements")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Supporting Views

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderTime") private var reminderTime = Date()
    
    var body: some View {
        Form {
            Section("Reminders") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                
                if notificationsEnabled {
                    DatePicker("Daily Reminder", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Export Your Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Export all your notes and categories to a backup file.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Export functionality
            }) {
                Text("Export Notes")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Section("Data Protection") {
                Text("Your notes are stored locally on your device and are not shared with any third parties.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Sticky Notes 3D")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("A modern, professional sticky notes app with 3D visualization.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AcknowledgementsView: View {
    var body: some View {
        Form {
            Section("Open Source Libraries") {
                Text("This app was built using SwiftUI, RealityKit, and other Apple frameworks.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}