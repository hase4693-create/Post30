//
//  PostListClassificationTests.swift
//  Post30Tests
//
//  改善項目1（投稿済み/未投稿はステータス基準・日付非依存）と
//  改善項目2（今月の投稿スコープ）の回帰テスト。
//

import XCTest
@testable import Post30

@MainActor
final class PostListClassificationTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "ja_JP")
        cal.timeZone = TimeZone.current
        return cal
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, tz: TimeZone? = nil) -> Date {
        var cal = calendar
        if let tz { cal.timeZone = tz }
        return cal.date(from: DateComponents(year: y, month: m, day: d))!
    }

    private func post(on date: Date, status: PostStatus) -> Post {
        Post(scheduledDate: date, platform: .threads, category: .other, content: "本文", status: status)
    }

    private func plan(_ posts: [Post]) -> MonthPlan {
        let p = MonthPlan(title: "計画", year: 2026, month: 8,
                          startDate: date(2026, 8, 1), endDate: date(2026, 8, 31))
        p.addPosts(posts)
        return p
    }

    // MARK: - 改善項目1：ステータス基準の分類（日付非依存）

    // 1. 未投稿データの投稿日を未来→過去に変えても未投稿のまま
    func testUnpublishedStaysUnpublishedWhenDateMovedToPast() {
        let p = post(on: date(2026, 8, 1), status: .scheduled) // 未来想定の予定
        _ = plan([p])
        p.scheduledDate = date(2020, 1, 1) // 過去へ変更

        XCTAssertTrue(PostListViewModel.Filter.unpublished.matches(p))
        XCTAssertFalse(PostListViewModel.Filter.published.matches(p))
    }

    // 2/3. 未投稿は「未投稿」一覧に出て「投稿済み」一覧に出ない
    func testUnpublishedAppearsOnlyInUnpublishedList() {
        let vm = PostListViewModel(plan: plan([post(on: date(2020, 1, 1), status: .scheduled)]))
        vm.selectedFilter = .unpublished
        XCTAssertEqual(vm.filteredPosts.count, 1)
        vm.selectedFilter = .published
        XCTAssertEqual(vm.filteredPosts.count, 0)
    }

    // 4. 投稿済みは投稿日に関係なく「投稿済み」一覧に出る（未来日でも）
    func testPublishedAppearsRegardlessOfDate() {
        let vm = PostListViewModel(plan: plan([post(on: date(2999, 12, 31), status: .published)]))
        vm.selectedFilter = .published
        XCTAssertEqual(vm.filteredPosts.count, 1)
        vm.selectedFilter = .unpublished
        XCTAssertEqual(vm.filteredPosts.count, 0)
    }

    // MARK: - 改善項目2：今月スコープ

    // 2/3/4/5. 当月月初は含む・翌月月初は含まない・前月末は含まない・当月末は含む
    func testCurrentMonthRange() {
        let posts = [
            post(on: date(2026, 12, 1), status: .scheduled),  // 当月月初
            post(on: date(2026, 12, 31), status: .scheduled), // 当月末
            post(on: date(2027, 1, 1), status: .scheduled),   // 翌月月初
            post(on: date(2026, 11, 30), status: .scheduled)  // 前月末
        ]
        let vm = PostListViewModel(plan: plan(posts), monthScope: date(2026, 12, 15), calendar: calendar)
        let dates = vm.filteredPosts.map { $0.scheduledDate }
        XCTAssertTrue(dates.contains { calendar.isDate($0, inSameDayAs: date(2026, 12, 1)) })
        XCTAssertTrue(dates.contains { calendar.isDate($0, inSameDayAs: date(2026, 12, 31)) })
        XCTAssertFalse(dates.contains { calendar.isDate($0, inSameDayAs: date(2027, 1, 1)) })
        XCTAssertFalse(dates.contains { calendar.isDate($0, inSameDayAs: date(2026, 11, 30)) })
    }

    // 6. 年末→年始の月境界
    func testYearBoundaryInterval() {
        let vm = PostListViewModel(plan: plan([]), monthScope: date(2026, 12, 10), calendar: calendar)
        let interval = vm.monthInterval
        XCTAssertNotNil(interval)
        XCTAssertTrue(calendar.isDate(interval!.start, inSameDayAs: date(2026, 12, 1)))
        XCTAssertTrue(calendar.isDate(interval!.end, inSameDayAs: date(2027, 1, 1)))
    }

    // 7. タイムゾーンを考慮して月範囲が計算される
    func testTimeZoneAwareInterval() {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "ja_JP")
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let scope = cal.date(from: DateComponents(year: 2026, month: 12, day: 15))!
        let vm = PostListViewModel(plan: plan([]), monthScope: scope, calendar: cal)
        let interval = vm.monthInterval
        XCTAssertNotNil(interval)
        // 月初は指定タイムゾーンの 12/1 0:00
        let expectedStart = cal.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        XCTAssertEqual(interval!.start, expectedStart)
    }

    // 9. 当月0件でもクラッシュせず空（isEmpty）
    func testEmptyMonthIsEmptyWithoutCrash() {
        let vm = PostListViewModel(
            plan: plan([post(on: date(2020, 1, 1), status: .scheduled)]), // 別月のみ
            monthScope: date(2026, 12, 15), calendar: calendar
        )
        XCTAssertTrue(vm.filteredPosts.isEmpty)
        XCTAssertTrue(vm.isEmpty)
    }

    // 1(改善2). ホームの「今月の投稿」から当月スコープの一覧VMが生成される
    func testHomeCreatesCurrentMonthListViewModel() {
        let now = date(2026, 8, 15)
        let posts = [
            post(on: date(2026, 8, 10), status: .scheduled), // 当月
            post(on: date(2026, 9, 10), status: .scheduled)  // 翌月
        ]
        let home = HomeViewModel(
            plan: plan(posts),
            clipboardService: NoopClipboard(),
            calendar: calendar,
            now: { now }
        )
        let listVM = home.makeCurrentMonthListViewModel()
        XCTAssertNotNil(listVM.monthInterval)
        XCTAssertEqual(listVM.filteredPosts.count, 1)
        XCTAssertTrue(listVM.filteredPosts.first?.scheduledDate.isSameDay(as: date(2026, 8, 10)) ?? false)
    }

    private struct NoopClipboard: ClipboardService {
        func copy(_ text: String) {}
    }
}
