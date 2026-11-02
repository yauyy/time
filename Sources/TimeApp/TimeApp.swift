import AppKit
import Combine
import SwiftUI
import TimeCore

@main
struct TimeApplication {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--diagnostics") {
            let preferences = ClockPreferences.load(from: UserDefaults.standard.data(forKey: ClockStore.preferencesKey))
            let now = Date()
            let bundleID = Bundle.main.bundleIdentifier ?? "me.yau.time"
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
            let info: [String: Any] = [
                "app": "Time",
                "primaryTimeZone": preferences.primaryTimeZoneID,
                "systemTimeZone": TimeZone.current.identifier,
                "menuBarTitle": ClockFormatter.menuBarTitle(at: now, preferences: preferences),
                "cities": preferences.timeZoneIDs,
                "time": ISO8601DateFormatter().string(from: now),
                "runningApplicationActive": runningApps.contains(where: \.isActive),
                "frontmostIsTime": NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleID
            ]
            if let data = try? JSONSerialization.data(withJSONObject: info, options: [.prettyPrinted, .sortedKeys]) {
                print(String(decoding: data, as: UTF8.self))
            }
            return
        }
        let app = NSApplication.shared
        // A per-process visual-review mode; it never changes macOS appearance or saved preferences.
        if CommandLine.arguments.contains("--preview-dark") {
            app.appearance = NSAppearance(named: .darkAqua)
        }
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let store = ClockStore()
    private var subscriptions = Set<AnyCancellable>()
    private var lastTitle: NSAttributedString?
    private var previousApplication: NSRunningApplication?
    private var presentationGeneration = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent accidental duplicate menu-bar clocks when launching a second copy.
        if let bundleID = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.autosaveName = "TimeWorldClock"
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            button.setAccessibilityIdentifier("time.menuBarClock")
        }
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 380, height: 590)
        popover.contentViewController = NSHostingController(rootView: ClockPopover(store: store))

        Publishers.CombineLatest(store.$now, store.$preferences)
            .sink { [weak self] date, preferences in self?.updateTitle(date: date, preferences: preferences) }
            .store(in: &subscriptions)
        updateTitle(date: store.now, preferences: store.preferences)
        // A menu-bar clock starts quietly, including at login. Only an explicit
        // click or reopen request should present a panel and request activation.
    }

    private func updateTitle(date: Date, preferences: ClockPreferences) {
        guard let button = statusItem?.button else { return }
        let title = ClockFormatter.menuBarTitle(at: date, preferences: preferences)
        let attributed = NSMutableAttributedString(string: title, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.labelColor
        ])
        if ClockFormatter.hideSeparators(at: date, preferences: preferences) {
            // Transparent separators keep their width, so the menu bar never jumps.
            for (index, codeUnit) in title.utf16.enumerated() where codeUnit == 58 {
                attributed.addAttribute(.foregroundColor, value: NSColor.clear, range: NSRange(location: index, length: 1))
            }
        }
        if lastTitle?.isEqual(to: attributed) != true {
            button.attributedTitle = attributed
            lastTitle = attributed
        }
        button.toolTip = "Time · \(ClockCity.resolve(preferences.primaryTimeZoneID).name)\n" +
            ClockFormatter.date(at: date, in: ClockCity.resolve(preferences.primaryTimeZoneID).timeZone, includeYear: true)
        button.setAccessibilityLabel("\(ClockCity.resolve(preferences.primaryTimeZoneID).name)时间 \(title)")
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else { showPopover() }
    }

    private func showPopover() {
        guard let button = statusItem?.button, !popover.isShown else { return }
        presentationGeneration += 1
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previousApplication = frontmost
        }
        store.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        if #available(macOS 14, *) { NSApp.activate() }
        else { NSApp.activate(ignoringOtherApps: false) }
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        let generation = presentationGeneration
        DispatchQueue.main.async { [weak self] in
            guard let self, generation == self.presentationGeneration, !self.popover.isShown else { return }
            let previous = self.previousApplication
            self.previousApplication = nil
            guard NSApp.isActive,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier,
                  let previous, !previous.isTerminated else { return }
            // Respect a user's switch to another app. Cooperatively return focus
            // only while Time still owns it, and never on a stale close event.
            if #available(macOS 14, *) { NSApp.yieldActivation(to: previous) }
            previous.activate(options: [])
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        DispatchQueue.main.async { [weak self] in self?.showPopover() }
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
    }
}
