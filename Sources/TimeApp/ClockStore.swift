import AppKit
import Combine
import ServiceManagement
import TimeCore

@MainActor
final class ClockStore: ObservableObject {
    @Published var now = Date()
    @Published var preferences: ClockPreferences {
        didSet {
            let valid = preferences.validated()
            if preferences != valid { preferences = valid }
            if let data = try? JSONEncoder().encode(preferences) {
                defaults.set(data, forKey: Self.preferencesKey)
            }
        }
    }
    @Published private(set) var loginStatus = SMAppService.mainApp.status
    @Published var loginError: String?

    static let preferencesKey = "clockPreferences.v1"
    private let defaults: UserDefaults
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preferences = ClockPreferences.load(from: defaults.data(forKey: Self.preferencesKey))
        let timer = Timer(fire: Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970) + 1.02),
                          interval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = Date() }
        }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        for name in [NSNotification.Name.NSSystemClockDidChange, .NSSystemTimeZoneDidChange] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            })
        }
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
                                                                           object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        })
    }

    var primaryCity: ClockCity { ClockCity.resolve(preferences.primaryTimeZoneID) }
    var cities: [ClockCity] { preferences.timeZoneIDs.map(ClockCity.resolve) }

    func refresh() {
        now = Date()
        loginStatus = SMAppService.mainApp.status
    }

    func select(_ city: ClockCity) {
        var updated = preferences
        if !updated.timeZoneIDs.contains(city.id) { updated.timeZoneIDs.append(city.id) }
        updated.primaryTimeZoneID = city.id
        preferences = updated
    }

    func add(_ city: ClockCity) {
        guard !preferences.timeZoneIDs.contains(city.id) else { return }
        preferences.timeZoneIDs.append(city.id)
    }

    func remove(_ city: ClockCity) {
        guard preferences.timeZoneIDs.count > 1 else { return }
        var updated = preferences
        updated.timeZoneIDs.removeAll { $0 == city.id }
        if updated.primaryTimeZoneID == city.id { updated.primaryTimeZoneID = updated.timeZoneIDs[0] }
        preferences = updated
    }

    func setLoginEnabled(_ enabled: Bool) {
        loginError = nil
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            loginError = "无法更新登录启动：\(error.localizedDescription)"
        }
        loginStatus = SMAppService.mainApp.status
    }

    var loginEnabled: Bool { loginStatus == .enabled || loginStatus == .requiresApproval }
    var loginNeedsApproval: Bool { loginStatus == .requiresApproval }

    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }

    func openClockSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!
        NSWorkspace.shared.open(url)
    }
}
