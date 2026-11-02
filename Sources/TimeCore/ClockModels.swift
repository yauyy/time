import Foundation

public struct ClockCity: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let region: String

    public init(id: String, name: String, region: String) {
        self.id = id
        self.name = name
        self.region = region
    }

    public var timeZone: TimeZone { TimeZone(identifier: id) ?? TimeZone(identifier: "Asia/Shanghai")! }

    public static let shanghai = ClockCity(id: "Asia/Shanghai", name: "上海", region: "中国")

    public static let featured: [ClockCity] = [
        .shanghai,
        .init(id: "Asia/Hong_Kong", name: "香港", region: "中国"),
        .init(id: "Asia/Taipei", name: "台北", region: "中国"),
        .init(id: "Asia/Tokyo", name: "东京", region: "日本"),
        .init(id: "Asia/Seoul", name: "首尔", region: "韩国"),
        .init(id: "Asia/Singapore", name: "新加坡", region: "新加坡"),
        .init(id: "Asia/Bangkok", name: "曼谷", region: "泰国"),
        .init(id: "Asia/Kolkata", name: "新德里", region: "印度"),
        .init(id: "Asia/Kathmandu", name: "加德满都", region: "尼泊尔"),
        .init(id: "Asia/Dubai", name: "迪拜", region: "阿联酋"),
        .init(id: "Europe/London", name: "伦敦", region: "英国"),
        .init(id: "Europe/Paris", name: "巴黎", region: "法国"),
        .init(id: "Europe/Berlin", name: "柏林", region: "德国"),
        .init(id: "Europe/Moscow", name: "莫斯科", region: "俄罗斯"),
        .init(id: "America/New_York", name: "纽约", region: "美国"),
        .init(id: "America/Chicago", name: "芝加哥", region: "美国"),
        .init(id: "America/Denver", name: "丹佛", region: "美国"),
        .init(id: "America/Los_Angeles", name: "洛杉矶", region: "美国"),
        .init(id: "America/Vancouver", name: "温哥华", region: "加拿大"),
        .init(id: "America/Toronto", name: "多伦多", region: "加拿大"),
        .init(id: "America/Sao_Paulo", name: "圣保罗", region: "巴西"),
        .init(id: "Pacific/Honolulu", name: "檀香山", region: "美国"),
        .init(id: "Australia/Sydney", name: "悉尼", region: "澳大利亚"),
        .init(id: "Australia/Adelaide", name: "阿德莱德", region: "澳大利亚"),
        .init(id: "Pacific/Auckland", name: "奥克兰", region: "新西兰"),
        .init(id: "Africa/Cairo", name: "开罗", region: "埃及"),
        .init(id: "Africa/Johannesburg", name: "约翰内斯堡", region: "南非"),
        .init(id: "Etc/UTC", name: "协调世界时", region: "UTC")
    ]

    public static func resolve(_ identifier: String) -> ClockCity {
        if let city = featured.first(where: { $0.id == identifier }) { return city }
        guard let zone = TimeZone(identifier: identifier) else { return .shanghai }
        let components = identifier.split(separator: "/")
        let name = components.last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? identifier
        let region = zone.localizedName(for: .generic, locale: Locale(identifier: "zh_CN")) ?? identifier
        return ClockCity(id: identifier, name: name, region: region)
    }

    private static let searchIndex: [(city: ClockCity, terms: [String])] = {
        let known = Set(featured.map(\.id))
        let others = TimeZone.knownTimeZoneIdentifiers.filter { !known.contains($0) }.map(resolve)
        return (featured + others).map { city in
            (city, [city.id, city.name, city.region, city.name.applyingTransform(.toLatin, reverse: false) ?? ""])
        }
    }()

    public static func search(_ query: String) -> [ClockCity] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return featured }
        return searchIndex.filter { entry in
            entry.terms.contains { $0.localizedStandardContains(query) }
        }.map(\.city)
    }
}

public struct ClockPreferences: Codable, Equatable, Sendable {
    public var primaryTimeZoneID: String = "Asia/Shanghai"
    public var timeZoneIDs: [String] = ["Asia/Shanghai", "America/Los_Angeles", "Europe/London", "Asia/Tokyo"]
    public var use24Hour = true
    public var showSeconds = false
    public var showDate = false
    public var showWeekday = false
    public var showAMPM = false
    public var blinkSeparators = false

    public init() {}

    public func validated() -> ClockPreferences {
        var result = self
        var seen = Set<String>()
        result.timeZoneIDs = timeZoneIDs.filter { TimeZone(identifier: $0) != nil && seen.insert($0).inserted }
        if TimeZone(identifier: primaryTimeZoneID) == nil { result.primaryTimeZoneID = "Asia/Shanghai" }
        if !result.timeZoneIDs.contains(result.primaryTimeZoneID) {
            result.timeZoneIDs.insert(result.primaryTimeZoneID, at: 0)
        }
        return result
    }

    public static func load(from data: Data?) -> ClockPreferences {
        guard let data, let decoded = try? JSONDecoder().decode(ClockPreferences.self, from: data) else {
            return ClockPreferences()
        }
        return decoded.validated()
    }
}

public enum ClockFormatter {
    // DateFormatter instances stay local so this core has no shared mutable state.
    private static func format(_ pattern: String, at date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    public static func time(at date: Date, in timeZone: TimeZone, use24Hour: Bool = true,
                            showSeconds: Bool = false, showAMPM: Bool = false) -> String {
        let pattern = (use24Hour ? "HH:mm" : "h:mm") + (showSeconds ? ":ss" : "")
        return format((!use24Hour && showAMPM ? "a " : "") + pattern, at: date, in: timeZone)
    }

    public static func date(at date: Date, in timeZone: TimeZone, includeYear: Bool = false) -> String {
        format(includeYear ? "yyyy年M月d日 EEEE" : "M月d日 EEEE", at: date, in: timeZone)
    }

    public static func menuBarTitle(at date: Date, preferences: ClockPreferences) -> String {
        let city = ClockCity.resolve(preferences.primaryTimeZoneID)
        var pieces: [String] = []
        if preferences.showDate { pieces.append(format("M月d日", at: date, in: city.timeZone)) }
        if preferences.showWeekday { pieces.append(format("EEE", at: date, in: city.timeZone)) }
        pieces.append(time(at: date, in: city.timeZone, use24Hour: preferences.use24Hour,
                           showSeconds: preferences.showSeconds, showAMPM: preferences.showAMPM))
        return pieces.joined(separator: " ")
    }

    public static func utcOffset(at date: Date, in timeZone: TimeZone) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let minutes = abs(seconds) / 60
        return String(format: "UTC%@%02d:%02d", seconds < 0 ? "−" : "+", minutes / 60, minutes % 60)
    }

    public static func relativeOffset(at date: Date, in timeZone: TimeZone, comparedTo reference: TimeZone) -> String {
        let minutes = (timeZone.secondsFromGMT(for: date) - reference.secondsFromGMT(for: date)) / 60
        if minutes == 0 { return "同一时间" }
        let magnitude = abs(minutes)
        let hours = magnitude / 60
        let remainder = magnitude % 60
        let amount = remainder == 0 ? "\(hours) 小时" : (hours == 0 ? "\(remainder) 分钟" : "\(hours) 小时 \(remainder) 分钟")
        return (minutes > 0 ? "快 " : "慢 ") + amount
    }

    public static func dayDifference(at date: Date, in timeZone: TimeZone, comparedTo reference: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let target = calendar.dateComponents([.year, .month, .day], from: date)
        calendar.timeZone = reference
        let origin = calendar.dateComponents([.year, .month, .day], from: date)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let targetDay = calendar.date(from: target), let originDay = calendar.date(from: origin) else { return 0 }
        return calendar.dateComponents([.day], from: originDay, to: targetDay).day ?? 0
    }

    public static func isDaytime(at date: Date, in timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return (7..<19).contains(calendar.component(.hour, from: date))
    }

    public static func hideSeparators(at date: Date, preferences: ClockPreferences) -> Bool {
        preferences.blinkSeparators && Int(floor(date.timeIntervalSince1970)) % 2 != 0
    }

    public static func menuBarDisplayTitle(for title: String, at date: Date, preferences: ClockPreferences) -> String {
        // A punctuation space matches the colon's advance in the system clock
        // font. Both blink phases remain ordinary, natively styled button text.
        hideSeparators(at: date, preferences: preferences)
            ? title.replacingOccurrences(of: ":", with: "\u{2008}") : title
    }
}
