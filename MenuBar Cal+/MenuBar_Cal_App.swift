import SwiftUI

@main
struct CalendarBarApp: App {

    init() {
        Task { @MainActor in
            StoreKitTransactionListener.shared.start()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            CalendarPopoverView()
        } label: {
            StatusItemLabel()
                .id(UUID())   // 🔥 FORCENÉ PŘERENDEROVÁNÍ labelu
        }
        .menuBarExtraStyle(.window)
        
        Window("Preferences", id: "preferences") {
            SettingsView()
                .frame(width: 420)
        }
        .windowResizability(.contentSize)
    }
}
