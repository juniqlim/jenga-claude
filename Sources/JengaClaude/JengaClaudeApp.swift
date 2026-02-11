import SwiftUI
import AppKit

@main
struct JengaClaudeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ChatView()
        }
        .commands {
            CommandMenu("Jenga") {
                Button("Effort 전환") {
                    NotificationCenter.default.post(name: .cycleEffort, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()

                Button("전체 토글") {
                    NotificationCenter.default.post(name: .toggleAll, object: nil)
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Button("활성만 복사") {
                    NotificationCenter.default.post(name: .copyActive, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("전체 복사") {
                    NotificationCenter.default.post(name: .copyAll, object: nil)
                }
                .keyboardShortcut("x", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let cycleEffort = Notification.Name("cycleEffort")
    static let toggleAll = Notification.Name("toggleAll")
    static let copyActive = Notification.Name("copyActive")
    static let copyAll = Notification.Name("copyAll")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
