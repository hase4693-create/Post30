//
//  DateExtensionsTests.swift
//  Post30Tests
//
//  Date 拡張の検証。
//

import XCTest
@testable import Post30

final class DateExtensionsTests: XCTestCase {

    private let calendar = Calendar.current

    func testIsSameDay() {
        let base = calendar.startOfDay(for: Date())
        let laterSameDay = base.addingTimeInterval(60 * 60 * 5) // 同日5時間後
        let nextDay = base.adding(days: 1)

        XCTAssertTrue(base.isSameDay(as: laterSameDay))
        XCTAssertFalse(base.isSameDay(as: nextDay))
    }

    func testAddingDays() {
        let base = calendar.startOfDay(for: Date())
        let plusThree = base.adding(days: 3)
        let diff = calendar.dateComponents([.day], from: base, to: plusThree).day
        XCTAssertEqual(diff, 3)
    }
}
