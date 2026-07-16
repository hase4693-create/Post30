//
//  HomeViewModelTests.swift
//  Post30Tests
//
//  HomeViewModel のロジック検証。View は対象外。
//  現在日時とクリップボードは注入で制御する。
//

import XCTest
@testable import Post30

final class HomeViewModelTests: XCTestCase {

    private let calendar = Calendar.current

    // MARK: - テスト用モック

    /// コピー内容を記録するモック。
    private final class MockClipboardService: ClipboardService {
        private(set) var copiedText: String?
        private(set) var callCount = 0
        func copy(_ text: String) {
            copiedText = text
            callCount += 1
        }
    }

    // MARK: - ヘルパー

    /// 指定時刻(hour)の固定日時を返す（2026-08-01 の hour 時）。
    private func fixedDate(hour: Int) -> Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 8
        comps.day = 1
        comps.hour = hour
        comps.minute = 0
        return calendar.date(from: comps)!
    }

    /// 状態が content の場合に HomeContent を取り出す。
    private func content(of viewModel: HomeViewModel) -> HomeContent? {
        if case .content(let content) = viewModel.state { return content }
        return nil
    }

    /// 状態が empty かどうか。
    private func isEmpty(_ viewModel: HomeViewModel) -> Bool {
        if case .empty = viewModel.state { return true }
        return false
    }

    private func makePlan(statuses: [(offset: Int, status: PostStatus)], startDay: Date) -> MonthPlan {
        let plan = MonthPlan(
            title: "テスト計画",
            year: 2026, month: 8,
            startDate: startDay,
            endDate: startDay.adding(days: 29),
            status: .active
        )
        let posts = statuses.map { item in
            Post(
                scheduledDate: startDay.adding(days: item.offset),
                scheduledTime: DateComponents(hour: 8, minute: 0),
                platform: .threads,
                category: .other,
                content: "本文\(item.offset)",
                status: item.status
            )
        }
        plan.addPosts(posts)
        return plan
    }

    private func makeViewModel(
        plan: MonthPlan?,
        now: Date,
        clipboard: ClipboardService = MockClipboardService()
    ) -> HomeViewModel {
        HomeViewModel(
            plan: plan,
            clipboardService: clipboard,
            calendar: calendar,
            now: { now }
        )
    }

    // MARK: - 1〜3. 挨拶

    func testMorningGreeting() {
        let vm = makeViewModel(plan: nil, now: fixedDate(hour: 8))
        XCTAssertEqual(vm.greeting, "おはようございます")
    }

    func testAfternoonGreeting() {
        let vm = makeViewModel(plan: nil, now: fixedDate(hour: 14))
        XCTAssertEqual(vm.greeting, "こんにちは")
    }

    func testEveningGreeting() {
        let vm = makeViewModel(plan: nil, now: fixedDate(hour: 21))
        XCTAssertEqual(vm.greeting, "こんばんは")
    }

    // 挨拶絵文字が時間帯に対応する
    func testGreetingEmojiByTimeOfDay() {
        XCTAssertEqual(makeViewModel(plan: nil, now: fixedDate(hour: 8)).greetingEmoji, "👋")
        XCTAssertEqual(makeViewModel(plan: nil, now: fixedDate(hour: 14)).greetingEmoji, "☀️")
        XCTAssertEqual(makeViewModel(plan: nil, now: fixedDate(hour: 21)).greetingEmoji, "🌙")
    }

    // MARK: - 4. 今日の投稿取得

    func testTodayPostIsRetrieved() {
        let today = calendar.startOfDay(for: fixedDate(hour: 9))
        let plan = makePlan(statuses: [(0, .scheduled), (1, .scheduled)], startDay: today)
        let vm = makeViewModel(plan: plan, now: fixedDate(hour: 9))

        let content = content(of: vm)
        XCTAssertNotNil(content?.todayPost)
        XCTAssertTrue(content?.todayPost?.scheduledDate.isSameDay(as: today) ?? false)
    }

    // MARK: - 5. 今日なし → 次回投稿取得

    func testNextPostWhenNoTodayPost() {
        let today = calendar.startOfDay(for: fixedDate(hour: 9))
        // 今日(0日目)は無く、2日後・4日後に予定
        let plan = makePlan(statuses: [(2, .scheduled), (4, .scheduled)], startDay: today)
        let vm = makeViewModel(plan: plan, now: fixedDate(hour: 9))

        let content = content(of: vm)
        XCTAssertNil(content?.todayPost)
        XCTAssertNotNil(content?.nextPost)
        XCTAssertTrue(content?.nextPost?.scheduledDate.isSameDay(as: today.adding(days: 2)) ?? false)
    }

    // MARK: - 6. 計画なし → empty

    func testEmptyWhenNoPlan() {
        let vm = makeViewModel(plan: nil, now: fixedDate(hour: 9))
        XCTAssertTrue(isEmpty(vm))
    }

    // MARK: - 7. 投稿0件 → empty

    func testEmptyWhenZeroPosts() {
        let plan = MonthPlan(
            title: "空", year: 2026, month: 9,
            startDate: Date(), endDate: Date()
        )
        let vm = makeViewModel(plan: plan, now: fixedDate(hour: 9))
        XCTAssertTrue(isEmpty(vm))
    }

    // MARK: - 8. 進捗値が MonthPlan と一致

    func testProgressValuesMatchPlan() {
        let today = calendar.startOfDay(for: fixedDate(hour: 9))
        let plan = makePlan(
            statuses: [(0, .published), (1, .published), (2, .scheduled), (3, .draft)],
            startDay: today
        )
        let vm = makeViewModel(plan: plan, now: fixedDate(hour: 9))

        XCTAssertEqual(vm.publishedCount, plan.publishedCount)
        XCTAssertEqual(vm.unpublishedCount, plan.unpublishedCount)
        XCTAssertEqual(vm.totalPostCount, plan.totalPostCount)
        XCTAssertEqual(vm.publishedProgressRate, plan.publishedProgressRate, accuracy: 0.0001)
    }

    // MARK: - 9〜12. markAsPublished

    func testMarkAsPublishedUpdatesPost() {
        let today = calendar.startOfDay(for: fixedDate(hour: 9))
        let plan = makePlan(statuses: [(0, .scheduled)], startDay: today)
        let publishTime = fixedDate(hour: 9)
        let vm = makeViewModel(plan: plan, now: publishTime)

        let post = content(of: vm)!.todayPost!
        let beforePublished = vm.publishedCount

        vm.markAsPublished(post)

        // 9. status が published
        XCTAssertEqual(post.status, .published)
        // 10. publishedAt が設定される
        XCTAssertEqual(post.publishedAt, publishTime)
        // 11. updatedAt が更新される
        XCTAssertEqual(post.updatedAt, publishTime)
        // 12. 件数・率が更新される
        XCTAssertEqual(vm.publishedCount, beforePublished + 1)
        XCTAssertEqual(vm.publishedProgressRate, plan.publishedProgressRate, accuracy: 0.0001)
    }

    // MARK: - 13. 二重処理しない

    func testMarkAsPublishedIsIdempotent() {
        let today = calendar.startOfDay(for: fixedDate(hour: 9))
        let plan = makePlan(statuses: [(0, .scheduled)], startDay: today)
        let vm = makeViewModel(plan: plan, now: fixedDate(hour: 9))

        let post = content(of: vm)!.todayPost!
        vm.markAsPublished(post)
        let firstPublishedAt = post.publishedAt
        let countAfterFirst = vm.publishedCount

        // 2回目は無視される
        vm.markAsPublished(post)
        XCTAssertEqual(post.publishedAt, firstPublishedAt)
        XCTAssertEqual(vm.publishedCount, countAfterFirst)
    }

    // MARK: - クリップボード（モック）

    func testCopyUsesClipboardServiceAndShowsToast() {
        let today = calendar.startOfDay(for: fixedDate(hour: 9))
        let plan = makePlan(statuses: [(0, .scheduled)], startDay: today)
        let mock = MockClipboardService()
        let vm = makeViewModel(plan: plan, now: fixedDate(hour: 9), clipboard: mock)

        let post = content(of: vm)!.todayPost!
        vm.copy(post)

        XCTAssertEqual(mock.copiedText, post.content)
        XCTAssertEqual(mock.callCount, 1)
        XCTAssertTrue(vm.showCopyToast)
    }
}
