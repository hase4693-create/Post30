//
//  PostTests.swift
//  Post30Tests
//
//  Post の予定日時生成・親子関係の検証。
//

import XCTest
@testable import Post30

final class PostTests: XCTestCase {

    private let calendar = Calendar.current

    // scheduledDate と scheduledTime から予定日時を安全に生成できる
    func testScheduledDateTimeIsComposed() {
        let day = calendar.startOfDay(for: Date())
        let post = Post(
            scheduledDate: day,
            scheduledTime: DateComponents(hour: 8, minute: 30)
        )
        let dateTime = post.scheduledDateTime()
        XCTAssertNotNil(dateTime)

        let comps = calendar.dateComponents([.hour, .minute], from: dateTime!)
        XCTAssertEqual(comps.hour, 8)
        XCTAssertEqual(comps.minute, 30)
        // 同じ日であること（日付は scheduledDate を維持）。
        XCTAssertTrue(dateTime!.isSameDay(as: day))
    }

    // 時刻が無い場合は nil（クラッシュしない）
    func testScheduledDateTimeIsNilWhenNoTime() {
        let post = Post(scheduledDate: Date(), scheduledTime: nil)
        XCTAssertNil(post.scheduledDateTime())
        XCTAssertNil(post.scheduledTimeText)
    }

    // hour/minute が欠落した DateComponents でもクラッシュしない
    func testScheduledDateTimeWithMissingComponents() {
        let post = Post(
            scheduledDate: Date(),
            scheduledTime: DateComponents(hour: 9) // minute 欠落
        )
        XCTAssertNil(post.scheduledDateTime())
        XCTAssertNil(post.scheduledTimeText)
    }

    // 不正な時刻（範囲外）でもクラッシュせず、表示文字列は安全に nil
    func testScheduledTimeTextWithInvalidValues() {
        let post = Post(
            scheduledDate: Date(),
            scheduledTime: DateComponents(hour: 99, minute: 61)
        )
        // 表示文字列は範囲チェックで nil を返す（クラッシュしない）。
        XCTAssertNil(post.scheduledTimeText)
        // scheduledDateTime は Calendar が不正値を解決できず nil（クラッシュしない）。
        XCTAssertNil(post.scheduledDateTime())
    }

    // 表示用文字列が期待どおり
    func testScheduledTimeTextFormat() {
        let post = Post(
            scheduledDate: Date(),
            scheduledTime: DateComponents(hour: 8, minute: 5)
        )
        XCTAssertEqual(post.scheduledTimeText, "08:05")
    }

    // 親子関係: addPost で親（plan）が設定される
    func testAddPostSetsParentRelationship() {
        let plan = MonthPlan(
            title: "計画",
            year: 2026,
            month: 8,
            startDate: Date(),
            endDate: Date()
        )
        let post = Post(scheduledDate: Date())
        XCTAssertNil(post.plan)
        plan.addPost(post)
        XCTAssertTrue(post.plan === plan)
        XCTAssertEqual(plan.totalPostCount, 1)
    }
}
