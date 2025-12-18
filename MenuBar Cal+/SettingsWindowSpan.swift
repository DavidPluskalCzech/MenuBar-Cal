import AppKit

enum SettingsWindowBringer {
    static func bringToFront() {
        // Vyloučíme MenuBarExtra okno
        let windows = NSApp.windows.filter { w in
            !String(describing: type(of: w)).contains("MenuBarExtra")
        }

        // Settings / Preferences (CZ/EN)
        let keys = ["Settings", "Preferences", "Nastavení", "Předvolby"]

        if let w = windows.first(where: { win in
            keys.contains(where: { win.title.localizedCaseInsensitiveContains($0) })
        }) {
            w.makeKeyAndOrderFront(nil)
            w.orderFrontRegardless()
        }
    }
}
