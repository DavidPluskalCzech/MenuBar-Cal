import AppKit
import SwiftUI

final class SettingsWindowStore {
    static let shared = SettingsWindowStore()
    weak var window: NSWindow?

    func bringToFront() {
        guard let w = window else { return }
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        w.orderFrontRegardless()
    }
}

// SwiftUI helper, který nám předá NSWindow, ve kterém běží SettingsView
struct WindowReader: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { [weak v] in
            guard let window = v?.window else { return }
            SettingsWindowStore.shared.window = window
        }
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            guard let window = nsView?.window else { return }
            SettingsWindowStore.shared.window = window
        }
    }
}
