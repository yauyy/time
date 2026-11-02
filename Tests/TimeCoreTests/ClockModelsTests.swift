import Foundation
import XCTest
@testable import TimeCore

final class ClockModelsTests: XCTestCase {
    private let shanghai = TimeZone(identifier: "Asia/Shanghai")!
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    private func instant(_ text: String, file: StaticString = #filePath, line: UInt = #line) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: text), "Invalid fixture: \(text)", file: file, line: line)
    }

    func testShanghaiCrossesIntoNextDay() throws {
        let date = try instant("2026-11-01T20:00:00Z")
        XCTAssertEqual(ClockFormatter.time(at: date, in: shanghai), "04:00")
        XCTAssertEqual(ClockFormatter.date(at: date, in: shanghai, includeYear: true), "2026年11月2日 星期一")
        XCTAssertEqual(ClockFormatter.menuBarTitle(at: date, preferences: ClockPreferences()), "04:00")
    }

    func testLosAngelesFallBackRepeatsOneOClockAndUpdatesOffset() throws {
        let before = try instant("2026-11-01T08:59:59Z")
        let after = before.addingTimeInterval(1)

        XCTAssertEqual(ClockFormatter.time(at: before, in: losAngeles, showSeconds: true), "01:59:59")
        XCTAssertEqual(ClockFormatter.utcOffset(at: before, in: losAngeles), "UTC−07:00")
        XCTAssertEqual(ClockFormatter.time(at: after, in: losAngeles, showSeconds: true), "01:00:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: after, in: losAngeles), "UTC−08:00")
        XCTAssertEqual(ClockFormatter.relativeOffset(at: before, in: shanghai, comparedTo: losAngeles), "快 15 小时")
        XCTAssertEqual(ClockFormatter.relativeOffset(at: after, in: shanghai, comparedTo: losAngeles), "快 16 小时")
    }

    func testLosAngelesSpringForwardSkipsTwoOClock() throws {
        let before = try instant("2026-03-08T09:59:59Z")
        let after = before.addingTimeInterval(1)

        XCTAssertEqual(ClockFormatter.time(at: before, in: losAngeles, showSeconds: true), "01:59:59")
        XCTAssertEqual(ClockFormatter.time(at: after, in: losAngeles, showSeconds: true), "03:00:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: before, in: losAngeles), "UTC−08:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: after, in: losAngeles), "UTC−07:00")
    }

    func testWinterAndSummerOffsetsUseTheSuppliedDate() throws {
        let winter = try instant("2026-01-15T12:00:00Z")
        let summer = try instant("2026-07-15T12:00:00Z")
        let london = try XCTUnwrap(TimeZone(identifier: "Europe/London"))

        XCTAssertEqual(ClockFormatter.utcOffset(at: winter, in: losAngeles), "UTC−08:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: summer, in: losAngeles), "UTC−07:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: winter, in: london), "UTC+00:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: summer, in: london), "UTC+01:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: winter, in: shanghai), "UTC+08:00")
        XCTAssertEqual(ClockFormatter.utcOffset(at: summer, in: shanghai), "UTC+08:00")
    }

    func testQuarterHourTimeZoneAndRelativeOffsetsAreNotRounded() throws {
        let date = try instant("2026-11-01T20:00:00Z")
        let kathmandu = try XCTUnwrap(TimeZone(identifier: "Asia/Kathmandu"))
        let kolkata = try XCTUnwrap(TimeZone(identifier: "Asia/Kolkata"))

        XCTAssertEqual(ClockFormatter.time(at: date, in: kathmandu), "01:45")
        XCTAssertEqual(ClockFormatter.utcOffset(at: date, in: kathmandu), "UTC+05:45")
        XCTAssertEqual(ClockFormatter.relativeOffset(at: date, in: kathmandu, comparedTo: shanghai), "慢 2 小时 15 分钟")
        XCTAssertEqual(ClockFormatter.relativeOffset(at: date, in: shanghai, comparedTo: kathmandu), "快 2 小时 15 分钟")
        XCTAssertEqual(ClockFormatter.relativeOffset(at: date, in: kathmandu, comparedTo: kolkata), "快 15 分钟")
        XCTAssertEqual(ClockFormatter.relativeOffset(at: date, in: shanghai, comparedTo: shanghai), "同一时间")
    }

    func testDayDifferenceAcrossYearBoundaryIsCalendarDayDifference() throws {
        let date = try instant("2026-12-31T20:00:00Z")

        XCTAssertEqual(ClockFormatter.dayDifference(at: date, in: shanghai, comparedTo: losAngeles), 1)
        XCTAssertEqual(ClockFormatter.dayDifference(at: date, in: losAngeles, comparedTo: shanghai), -1)
        XCTAssertEqual(ClockFormatter.dayDifference(at: date, in: shanghai, comparedTo: shanghai), 0)
        XCTAssertEqual(ClockFormatter.date(at: date, in: shanghai, includeYear: true), "2027年1月1日 星期五")
    }

    func testDayDifferenceCanBeTwoAcrossInternationalDateLine() throws {
        let date = try instant("2026-11-01T10:30:00Z")
        let kiritimati = try XCTUnwrap(TimeZone(identifier: "Pacific/Kiritimati"))
        let pagoPago = try XCTUnwrap(TimeZone(identifier: "Pacific/Pago_Pago"))

        XCTAssertEqual(ClockFormatter.dayDifference(at: date, in: kiritimati, comparedTo: pagoPago), 2)
        XCTAssertEqual(ClockFormatter.dayDifference(at: date, in: pagoPago, comparedTo: kiritimati), -2)
    }

    func testTwelveHourMidnightNoonAndAMPMOption() throws {
        let midnight = try instant("2026-11-01T16:00:00Z")
        let noon = try instant("2026-11-02T04:00:00Z")

        XCTAssertEqual(ClockFormatter.time(at: midnight, in: shanghai, use24Hour: false), "12:00")
        XCTAssertEqual(ClockFormatter.time(at: midnight, in: shanghai, use24Hour: false, showAMPM: true), "上午 12:00")
        XCTAssertEqual(ClockFormatter.time(at: noon, in: shanghai, use24Hour: false, showAMPM: true), "下午 12:00")
        XCTAssertEqual(ClockFormatter.time(at: midnight, in: shanghai, showAMPM: true), "00:00")
        XCTAssertEqual(ClockFormatter.time(at: noon, in: shanghai, showAMPM: true), "12:00")
    }

    func testMenuBarCombinesDateWeekdayAndSeconds() throws {
        let date = try instant("2026-11-01T20:05:06Z")
        var preferences = ClockPreferences()
        preferences.showDate = true
        preferences.showWeekday = true
        preferences.showSeconds = true

        XCTAssertEqual(
            ClockFormatter.menuBarTitle(at: date, preferences: preferences),
            "11月2日 周一 04:05:06"
        )
    }

    func testMenuBarCanUseTwelveHourClockWithAMPM() throws {
        let date = try instant("2026-11-01T20:05:06Z")
        var preferences = ClockPreferences()
        preferences.use24Hour = false
        preferences.showAMPM = true

        XCTAssertEqual(
            ClockFormatter.menuBarTitle(at: date, preferences: preferences),
            "上午 4:05"
        )
    }

    func testMenuBarUsesSelectedTimeZoneWithoutCityName() throws {
        let date = try instant("2026-11-01T20:05:06Z")
        var preferences = ClockPreferences()
        preferences.primaryTimeZoneID = "America/Los_Angeles"
        XCTAssertEqual(ClockFormatter.menuBarTitle(at: date, preferences: preferences), "12:05")
    }

    func testDateAndWeekdayAreIndependentDisplaySettings() throws {
        let date = try instant("2026-11-01T20:05:06Z")
        var preferences = ClockPreferences()
        preferences.showDate = true
        XCTAssertEqual(ClockFormatter.menuBarTitle(at: date, preferences: preferences), "11月2日 04:05")
        preferences.showDate = false
        preferences.showWeekday = true
        XCTAssertEqual(ClockFormatter.menuBarTitle(at: date, preferences: preferences), "周一 04:05")
    }

    func testBlinkingDependsOnWholeSecondAndDoesNotChangeTitle() throws {
        let even = try instant("2026-11-01T20:05:06Z")
        let odd = even.addingTimeInterval(1)
        var preferences = ClockPreferences()

        XCTAssertFalse(ClockFormatter.hideSeparators(at: odd, preferences: preferences))
        preferences.blinkSeparators = true
        XCTAssertFalse(ClockFormatter.hideSeparators(at: even, preferences: preferences))
        XCTAssertFalse(ClockFormatter.hideSeparators(at: even.addingTimeInterval(0.9), preferences: preferences))
        XCTAssertTrue(ClockFormatter.hideSeparators(at: odd, preferences: preferences))
        XCTAssertEqual(ClockFormatter.menuBarTitle(at: even, preferences: preferences), ClockFormatter.menuBarTitle(at: odd, preferences: preferences))
    }

    func testDaytimeBoundaryUsesTargetTimeZone() throws {
        let before = try instant("2026-11-01T22:59:59Z")
        let start = before.addingTimeInterval(1)
        let end = try instant("2026-11-02T11:00:00Z")

        XCTAssertFalse(ClockFormatter.isDaytime(at: before, in: shanghai))
        XCTAssertTrue(ClockFormatter.isDaytime(at: start, in: shanghai))
        XCTAssertTrue(ClockFormatter.isDaytime(at: end.addingTimeInterval(-1), in: shanghai))
        XCTAssertFalse(ClockFormatter.isDaytime(at: end, in: shanghai))
    }

    func testPreferencesRemoveInvalidAndDuplicateCitiesWithoutReordering() {
        var preferences = ClockPreferences()
        preferences.timeZoneIDs = ["Europe/London", "not/a/zone", "Europe/London", "Asia/Shanghai", "Asia/Tokyo", "Asia/Tokyo"]

        XCTAssertEqual(preferences.validated().timeZoneIDs, ["Europe/London", "Asia/Shanghai", "Asia/Tokyo"])
        XCTAssertEqual(preferences.validated().primaryTimeZoneID, "Asia/Shanghai")
    }

    func testInvalidPrimaryFallsBackToShanghaiAndEmptyCitiesRemainUsable() {
        var preferences = ClockPreferences()
        preferences.primaryTimeZoneID = "not/a/zone"
        preferences.timeZoneIDs = []

        XCTAssertEqual(preferences.validated().primaryTimeZoneID, "Asia/Shanghai")
        XCTAssertEqual(preferences.validated().timeZoneIDs, ["Asia/Shanghai"])
        XCTAssertEqual(ClockCity.resolve("not/a/zone"), .shanghai)
    }

    func testMissingValidPrimaryIsInsertedBeforeOtherCities() {
        var preferences = ClockPreferences()
        preferences.primaryTimeZoneID = "Europe/Paris"
        preferences.timeZoneIDs = ["Asia/Tokyo", "Europe/London"]

        XCTAssertEqual(preferences.validated().timeZoneIDs, ["Europe/Paris", "Asia/Tokyo", "Europe/London"])
    }

    func testMissingAndMalformedJSONRestoreDefaults() {
        XCTAssertEqual(ClockPreferences.load(from: nil), ClockPreferences())
        XCTAssertEqual(ClockPreferences.load(from: Data("broken json".utf8)), ClockPreferences())
        XCTAssertEqual(ClockPreferences.load(from: Data("[]".utf8)), ClockPreferences())
    }

    func testPreferencesRoundTripAllNativeDisplaySettingsAndValidateLoadedData() throws {
        var preferences = ClockPreferences()
        preferences.use24Hour = false
        preferences.showSeconds = true
        preferences.showDate = true
        preferences.showWeekday = true
        preferences.showAMPM = true
        preferences.blinkSeparators = true

        XCTAssertEqual(ClockPreferences.load(from: try JSONEncoder().encode(preferences)), preferences)

        preferences.primaryTimeZoneID = "invalid"
        preferences.timeZoneIDs = ["Europe/London", "Europe/London", "invalid"]
        let loaded = ClockPreferences.load(from: try JSONEncoder().encode(preferences))
        XCTAssertEqual(loaded.primaryTimeZoneID, "Asia/Shanghai")
        XCTAssertEqual(loaded.timeZoneIDs, ["Asia/Shanghai", "Europe/London"])
    }

    func testLegacyRemovedSettingsAreIgnoredWithoutLosingRemainingPreferences() throws {
        let legacyJSON = Data("""
        {
            "primaryTimeZoneID": "Asia/Tokyo",
            "timeZoneIDs": ["Asia/Tokyo", "Europe/London"],
            "use24Hour": false,
            "showSeconds": true,
            "showDate": true,
            "showWeekday": true,
            "showCity": true,
            "showLocalTime": true,
            "showAMPM": true,
            "blinkSeparators": true
        }
        """.utf8)
        var expected = ClockPreferences()
        expected.primaryTimeZoneID = "Asia/Tokyo"
        expected.timeZoneIDs = ["Asia/Tokyo", "Europe/London"]
        expected.use24Hour = false
        expected.showSeconds = true
        expected.showDate = true
        expected.showWeekday = true
        expected.showAMPM = true
        expected.blinkSeparators = true

        let loaded = ClockPreferences.load(from: legacyJSON)
        XCTAssertEqual(loaded, expected)
        let date = try instant("2026-11-01T20:05:06Z")
        XCTAssertEqual(ClockFormatter.menuBarTitle(at: date, preferences: loaded), "11月2日 周一 上午 5:05:06")

        let encoded = try JSONEncoder().encode(loaded)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNil(object["showCity"])
        XCTAssertNil(object["showLocalTime"])
    }

    func testEmptyCitySearchReturnsFeaturedCitiesInTheirOriginalOrder() {
        XCTAssertEqual(ClockCity.search(""), ClockCity.featured)
        XCTAssertEqual(ClockCity.search("   \n\t"), ClockCity.featured)
    }

    func testCitySearchFindsChineseAndEnglishCityNames() {
        XCTAssertTrue(ClockCity.search("上海").contains(.shanghai))
        XCTAssertTrue(ClockCity.search("Shanghai").contains(.shanghai))
        XCTAssertTrue(ClockCity.search(" shanghai ").contains(.shanghai))
        XCTAssertTrue(ClockCity.search("Los_Angeles").contains { $0.id == "America/Los_Angeles" })
    }

    func testCitySearchIncludesTimeZonesOutsideFeaturedCities() {
        XCTAssertFalse(ClockCity.featured.contains { $0.id == "Europe/Zurich" })
        XCTAssertTrue(ClockCity.search("Europe/Zurich").contains { $0.id == "Europe/Zurich" })
    }

    func testCitySearchReturnsNoResultsWhenNothingMatches() {
        XCTAssertTrue(ClockCity.search("this city does not exist").isEmpty)
    }
}
