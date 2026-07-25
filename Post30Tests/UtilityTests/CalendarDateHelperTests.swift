//
//  CalendarDateHelperTests.swift
//  Post30Tests
//
//  カレンダー日付ロジックの検証（純ロジック・SwiftData 不要）。
//

import XCTest
@testable import Post30

final class CalendarDateHelperTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "ja_JP")
        cal.firstWeekday = 1 // 日曜始まり
        cal.timeZone = TimeZone.current
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// 当月セル数を数える。
    private func inMonthCount(_ grid: [CalendarDay]) -> Int {
        grid.filter { $0.isInDisplayedMonth }.count
    }

    // 1. 指定月の日付セルが正しく生成される（週で割り切れる・当月日が連続）
    func testGridIsWellFormed() {
        let grid = CalendarDateHelper.makeMonthGrid(for: date(2026, 8, 1), calendar: calendar)
        XCTAssertEqual(grid.count % 7, 0)
        let inMonth = grid.filter { $0.isInDisplayedMonth }
        // 当月日が 1 日ずつ連続している
        for index in 1..<inMonth.count {
            let expected = calendar.date(byAdding: .day, value: 1, to: inMonth[index - 1].date)!
            XCTAssertTrue(calendar.isDate(inMonth[index].date, inSameDayAs: expected))
        }
    }

    // 2. 28日の月（2023年2月）
    func testFebruary28() {
        XCTAssertEqual(inMonthCount(CalendarDateHelper.makeMonthGrid(for: date(2023, 2, 1), calendar: calendar)), 28)
    }

    // 3. 29日の月（2024年2月・うるう年）
    func testFebruary29LeapYear() {
        XCTAssertEqual(inMonthCount(CalendarDateHelper.makeMonthGrid(for: date(2024, 2, 1), calendar: calendar)), 29)
    }

    // 4. 30日の月（2023年4月）
    func testApril30() {
        XCTAssertEqual(inMonthCount(CalendarDateHelper.makeMonthGrid(for: date(2023, 4, 1), calendar: calendar)), 30)
    }

    // 5. 31日の月（2023年1月）
    func testJanuary31() {
        XCTAssertEqual(inMonthCount(CalendarDateHelper.makeMonthGrid(for: date(2023, 1, 1), calendar: calendar)), 31)
    }

    // 6. 月初が日曜日（2023年1月1日は日曜）→ 先頭補助日なし
    func testMonthStartingSunday() {
        let grid = CalendarDateHelper.makeMonthGrid(for: date(2023, 1, 1), calendar: calendar)
        let leading = grid.prefix { !$0.isInDisplayedMonth }.count
        XCTAssertEqual(leading, 0)
        XCTAssertTrue(grid.first?.isInDisplayedMonth ?? false)
    }

    // 7. 月初が土曜日（2023年4月1日は土曜）→ 先頭補助日6
    func testMonthStartingSaturday() {
        let grid = CalendarDateHelper.makeMonthGrid(for: date(2023, 4, 1), calendar: calendar)
        let leading = grid.prefix { !$0.isInDisplayedMonth }.count
        XCTAssertEqual(leading, 6)
    }

    // 先頭補助日数は Calendar の曜日と一致する（汎用検証）
    func testLeadingMatchesWeekday() {
        let first = date(2026, 8, 1)
        let grid = CalendarDateHelper.makeMonthGrid(for: first, calendar: calendar)
        let leading = grid.prefix { !$0.isInDisplayedMonth }.count
        let expected = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        XCTAssertEqual(leading, expected)
    }

    // 8. 前月移動
    func testPreviousMonth() {
        let prev = CalendarDateHelper.month(byAddingMonths: -1, to: date(2026, 8, 10), calendar: calendar)
        XCTAssertEqual(calendar.component(.year, from: prev), 2026)
        XCTAssertEqual(calendar.component(.month, from: prev), 7)
    }

    // 9. 次月移動
    func testNextMonth() {
        let next = CalendarDateHelper.month(byAddingMonths: 1, to: date(2026, 8, 10), calendar: calendar)
        XCTAssertEqual(calendar.component(.month, from: next), 9)
    }

    // 10. 12月 → 翌年1月
    func testDecemberToJanuary() {
        let next = CalendarDateHelper.month(byAddingMonths: 1, to: date(2026, 12, 1), calendar: calendar)
        XCTAssertEqual(calendar.component(.year, from: next), 2027)
        XCTAssertEqual(calendar.component(.month, from: next), 1)
    }

    // 11. 1月 → 前年12月
    func testJanuaryToDecember() {
        let prev = CalendarDateHelper.month(byAddingMonths: -1, to: date(2026, 1, 1), calendar: calendar)
        XCTAssertEqual(calendar.component(.year, from: prev), 2025)
        XCTAssertEqual(calendar.component(.month, from: prev), 12)
    }

    // 12. 同一日の判定で時刻差を無視できる
    func testSameDayIgnoresTime() {
        let morning = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: date(2026, 8, 15))!
        let night = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: date(2026, 8, 15))!
        XCTAssertTrue(CalendarDateHelper.isSameDay(morning, night, calendar: calendar))
        XCTAssertFalse(CalendarDateHelper.isSameDay(morning, date(2026, 8, 16), calendar: calendar))
    }

    // 23. 年月表示が日本語ロケールで適切
    func testMonthTitleJapanese() {
        let title = CalendarDateHelper.monthTitle(for: date(2026, 8, 1), calendar: calendar, locale: Locale(identifier: "ja_JP"))
        XCTAssertTrue(title.contains("2026"))
        XCTAssertTrue(title.contains("年"))
        XCTAssertTrue(title.contains("8"))
        XCTAssertTrue(title.contains("月"))
    }
}
