//
//  MonthPlanTests.swift
//  Post30Tests
//
//  MonthPlan の集計・取得ロジックの検証。
//

import XCTest
@testable import Post30

final class MonthPlanTests: XCTestCase {

    private let calendar = Calendar.current

    /// 指定日を起点に、状態を指定して投稿を持つ計画を作る。
    private func makePlan(startDate: Date, statuses: [PostStatus]) -> MonthPlan {
        let plan = MonthPlan(
            title: "テスト計画",
            year: 2026,
            month: 8,
            startDate: startDate,
            endDate: startDate.adding(days: statuses.count - 1),
            status: .active
        )
        let posts = statuses.enumerated().map { index, status in
            Post(
                scheduledDate: startDate.adding(days: index),
                platform: .threads,
                category: .other,
                content: "本文\(index)",
                status: status
            )
        }
        plan.addPosts(posts)
        return plan
    }

    // 1. 総投稿数
    func testTotalPostCount() {
        let plan = makePlan(startDate: Date(), statuses: [.draft, .scheduled, .published])
        XCTAssertEqual(plan.totalPostCount, 3)
    }

    // 2. 投稿済み件数
    func testPublishedCount() {
        let plan = makePlan(startDate: Date(), statuses: [.published, .published, .scheduled, .draft])
        XCTAssertEqual(plan.publishedCount, 2)
    }

    // 3. 未投稿件数（draft + scheduled のみ。published/skipped は除外）
    func testUnpublishedCount() {
        let plan = makePlan(startDate: Date(), statuses: [.published, .scheduled, .draft, .skipped])
        // scheduled + draft = 2
        XCTAssertEqual(plan.unpublishedCount, 2)
    }

    // 3-a. draft は未投稿に含まれる
    func testDraftIsCountedAsUnpublished() {
        let plan = makePlan(startDate: Date(), statuses: [.draft])
        XCTAssertEqual(plan.unpublishedCount, 1)
    }

    // 3-b. scheduled は未投稿に含まれる
    func testScheduledIsCountedAsUnpublished() {
        let plan = makePlan(startDate: Date(), statuses: [.scheduled])
        XCTAssertEqual(plan.unpublishedCount, 1)
    }

    // 3-c. published は未投稿に含まれない
    func testPublishedIsNotCountedAsUnpublished() {
        let plan = makePlan(startDate: Date(), statuses: [.published])
        XCTAssertEqual(plan.unpublishedCount, 0)
    }

    // 3-d. skipped は未投稿に含まれない
    func testSkippedIsNotCountedAsUnpublished() {
        let plan = makePlan(startDate: Date(), statuses: [.skipped])
        XCTAssertEqual(plan.unpublishedCount, 0)
    }

    // 4. 投稿0件でも完了率は0（ゼロ除算しない）
    func testProgressIsZeroWhenEmpty() {
        let plan = MonthPlan(
            title: "空の計画",
            year: 2026,
            month: 9,
            startDate: Date(),
            endDate: Date(),
            status: .draft
        )
        XCTAssertEqual(plan.totalPostCount, 0)
        XCTAssertEqual(plan.publishedProgressRate, 0)
    }

    // 5. 完了率が正しく計算される
    func testProgressIsCalculated() {
        let plan = makePlan(startDate: Date(), statuses: [.published, .published, .scheduled, .scheduled])
        XCTAssertEqual(plan.publishedProgressRate, 0.5, accuracy: 0.0001)
    }

    // 6. 指定日の投稿を正しく取得できる
    func testPostsOnDate() {
        let start = calendar.startOfDay(for: Date())
        let plan = makePlan(startDate: start, statuses: [.scheduled, .scheduled, .scheduled])
        let target = start.adding(days: 1)

        let result = plan.posts(on: target)
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.scheduledDate.isSameDay(as: target) ?? false)
    }

    // 7. 次の投稿予定を正しく取得できる
    func testNextScheduledPost() {
        let start = calendar.startOfDay(for: Date())
        // 0日目:投稿済み / 1日目:予定 / 2日目:予定
        let plan = makePlan(startDate: start, statuses: [.published, .scheduled, .scheduled])

        let next = plan.nextScheduledPost(after: start)
        XCTAssertNotNil(next)
        // 投稿済みは除外され、最も早い予定（1日目）が返る。
        XCTAssertTrue(next?.scheduledDate.isSameDay(as: start.adding(days: 1)) ?? false)
    }
}
