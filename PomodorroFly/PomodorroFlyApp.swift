//
//  PomodorroFlyApp.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//
import SwiftUI
import AppKit
import FirebaseCore

@main
struct PomodorroFlyApp: App {
    init() {
            FirebaseApp.configure()
        }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 400, height: 400)
                .background(WindowConfigurator()) // atașăm configuratorul
        }
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Setează dimensiune fixă
                window.setContentSize(NSSize(width: 400, height: 400))
                window.styleMask.remove(.resizable) // dezactivează redimensionarea

                // Disable zoom (maximize) and miniaturize (minimize)
                window.styleMask.remove(.miniaturizable)
                window.standardWindowButton(.zoomButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true

                // Keep only close button visible
                window.standardWindowButton(.closeButton)?.isHidden = false

                // Prevent window from being moved
                window.isMovable = false
                window.isMovableByWindowBackground = false

                window.minSize = NSSize(width: 400, height: 400)
                window.maxSize = NSSize(width: 400, height: 400)
                // Opțional: centrează fereastra
                window.center()
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
