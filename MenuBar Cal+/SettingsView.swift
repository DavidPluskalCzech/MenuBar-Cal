import SwiftUI
import ServiceManagement


//Settings - general - checkboxes
struct SettingsView: View {
    @AppStorage("showWeekNumber") private var showWeekNumber: Bool = false
    @AppStorage("showTime") private var showTime: Bool = false
    @AppStorage("dateStyle") private var dateStyleRaw: Int = 0
    @AppStorage("showIcon") private var showIcon: Bool = true
    @AppStorage("showDate") private var showDate: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    @State private var feedbackText: String = ""
    @State private var showThanksAlert: Bool = false
    @State private var showTipThanksAlert: Bool = false
    
    //Last settings toggle stays always active
    private var enabledCount: Int {
        [showDate, showTime, showWeekNumber, showIcon].filter { $0 }.count
    }

    private func disabling(_ toggle: Bool) -> Bool {
        toggle == true && enabledCount == 1
    }

    var body: some View {
        TabView {
            
    
                // Obecné nastavení
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {

                        Text("general_title")
                            .font(.title2.bold())

                        // Přepínače
                        Grid(
                            alignment: .leading,
                            horizontalSpacing: 20,
                            verticalSpacing: 12
                        ) {

                            GridRow {
                                Text("general_show_date")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Toggle("", isOn: $showDate)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .disabled(disabling(showDate))
                            }

                            GridRow {
                                Text("general_show_time")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Toggle("", isOn: $showTime)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .disabled(disabling(showTime))
                            }

                            GridRow {
                                Text("general_show_week_number")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Toggle("", isOn: $showWeekNumber)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .disabled(disabling(showWeekNumber))
                            }

                            GridRow {
                                Text("general_show_icon")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Toggle("", isOn: $showIcon)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .disabled(disabling(showIcon))
                            }
                            
                            GridRow {
                                Text("general_launch_at_login")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Toggle("", isOn: $launchAtLogin)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .onChange(of: launchAtLogin) { _, newValue in
                                        LaunchAtLogin.setEnabled(newValue)
                                    }
                                    .onAppear {
                                        // srovná toggle podle reálného stavu v systému (když to uživatel změnil v macOS nastavení)
                                        launchAtLogin = LaunchAtLogin.isEnabled
                                    }
                            }
                            .padding(.top, 16)   // větší mezera = vizuální oddělení
                            
                        }
                        


                        Divider()

                        Text("general_date_format_title")
                            .font(.headline)

                        Picker("", selection: $dateStyleRaw) {
                            Text("general_date_format_short").tag(0)
                            Text("general_date_format_medium").tag(1)
                            Text("general_date_format_long").tag(2)
                        }
                        .pickerStyle(.radioGroup)
                        
                        
                    
                        .padding(.vertical, 9)

                        HStack {
                            Spacer()

                            Button {
                                NSApp.terminate(nil)
                            } label: {
                                Text(NSLocalizedString("quit_app", comment: ""))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.secondary)

                            Spacer()
                        }

                    }
                    .padding(20)
                }
                .scrollDisabled(true)
                .tabItem {
                    Label("tab_general", systemImage: "slider.horizontal.3")
                }

            // Zpětná vazba
            VStack(alignment: .leading, spacing: 16) {
                Text("tab_feedback")
                    .font(.title2.bold())

                Text("feedback_subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {

                    ZStack(alignment: .topLeading) {

                        // Placeholder TextEditor
                        if feedbackText.isEmpty {
                            Text("feedback_placeholder")
                                .foregroundColor(Color.primary.opacity(0.45))
                                .padding(.top, 6)
                                .padding(.leading, 8)
                                .allowsHitTesting(false)
                                .zIndex(1) //Text editor layer
                        }

                        TextEditor(text: $feedbackText)
                            .padding(.top, 8)
                            .padding(.horizontal, 4)
                            .frame(minHeight: 180)
                            .background(Color.clear)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        
                        //Capital letter
                            .onChange(of: feedbackText) { oldValue, newValue in
                                guard oldValue != newValue else { return }
                                guard !newValue.isEmpty else { return }

                                let first = String(newValue.prefix(1)).uppercased()
                                let rest = String(newValue.dropFirst())

                                let corrected = first + rest

                                if corrected != newValue {
                                    feedbackText = corrected
                                }
                            }
                        
                    }
                }
                
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

                HStack {
                    Spacer()
                    Button {
                        sendFeedback()
                    } label: {
                        Label("feedback_send", systemImage: "paperplane")
                    }
                    .keyboardShortcut(.defaultAction)
                    Spacer()
                }
                
                .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction) //Send button inactive when txtEdit empty

                Spacer()
            }
            .padding(20)
            .alert("feedback_thanks", isPresented: $showThanksAlert) {
                Button("OK", role: .cancel) { }
            }
            .tabItem {
                Label("Feedback", systemImage: "bubble.left.and.bubble.right")
            }

            // Tip Jar
            TipJarView(showThanksAlert: $showTipThanksAlert)
                .padding(20)
                .alert("support_thanks", isPresented: $showTipThanksAlert) {
                    Button("support_thanks_button", role: .cancel) { }
                }
                .tabItem {
                    Label("tab_support", systemImage: "heart")
                }
        }
        .padding(.top, 12)
    }

    private func sendFeedback() {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let recipient = "davethepcguy@proton.me"
        let subject = "CalendarBar – Feedback"
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:\(recipient)?subject=\(subjectEncoded)&body=\(bodyEncoded)"

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)

            // jemná vizuální odezva – fade-out, fade-in
            withAnimation(.easeOut(duration: 0.15)) {
                feedbackText = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.12)) { }
            }
        }
    }
}

@MainActor
enum LaunchAtLoginManager {
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("LaunchAtLogin error:", error.localizedDescription)
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
