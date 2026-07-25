//
//  CalendarViewModelTests.swift
//  Post30Tests
//
//  カレンダー ViewModel のロジック検証。
//

import XCTest
@testable import Post30

final class CalendarViewModelTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "ja_JP")
        cal.firstWeekday = 1
        cal.timeZone = TimeZone.current
        return cal
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makePost(on date: Date, status: PostStatus, hour: Int = 8, minute: Int = 0) -> Post {
        Post(
            scheduledDate: calendar.startOfDay(for: date),
            scheduledTime: DateComponents(hour: hour, minute: minute),
            platform: .threads, category: .other,
            content: "本文", status: status
        )
    }

    private func makePlan(_ posts: [Post]) -> MonthPlan {
        let plan = MonthPlan(
            title: "テスト計画", year: 2026, month: 8,
            startDate: day(2026, 8, 1), endDate: day(2026, 8, 31), status: .active
        )
        plan.addPosts(posts)
        return plan
    }

    private func makeVM(plan: MonthPlan?, now: Date = Date()) -> CalendarViewModel {
        CalendarViewModel(plan: plan, calendar: calendar, now: { now })
    }

    // 13. 指定日付の投稿だけを抽出できる
    func testExtractPostsForDate() {
        let plan = makePlan([
            makePost(on: day(2026, 8, 10), status: .scheduled),
            makePost(on: day(2026, 8, 11), status: .scheduled)
        ])
        let vm = makeVM(plan: plan)
        XCTAssertEqual(vm.posts(on: day(2026, 8, 10)).count, 1)
        XCTAssertTrue(vm.posts(on: day(2026, 8, 10)).first?.scheduledDate.isSameDay(as: day(2026, 8, 10)) ?? false)
    }

    // 14. 投稿0件の日
    func testDayWithNoPosts() {
        let vm = makeVM(plan: makePlan([makePost(on: day(2026, 8, 10), status: .scheduled)]))
        XCTAssertEqual(vm.postCount(on: day(2026, 8, 20)), 0)
        XCTAssertEqual(vm.dayStatus(for: day(2026, 8, 20)), .none)
    }

    // 15. 投稿1件の日
    func testDayWithOnePost() {
        let vm = makeVM(plan: makePlan([makePost(on: day(2026, 8, 10), status: .scheduled)]))
        XCTAssertEqual(vm.postCount(on: day(2026, 8, 10)), 1)
    }

    // 16. 投稿複数件の日（時刻順に並ぶ）
    func testDayWithMultiplePostsSorted() {
        let plan = makePlan([
            makePost(on: day(2026, 8, 10), status: .scheduled, hour: 19),
            makePost(on: day(2026, 8, 10), status: .scheduled, hour: 8)
        ])
        let vm = makeVM(plan: plan)
        let posts = vm.posts(on: day(2026, 8, 10))
        XCTAssertEqual(posts.count, 2)
        XCTAssertEqual(posts.first?.scheduledHour, 8)
    }

    // 17. 未投稿のみの日
    func testUnpublishedOnly() {
        let plan = makePlan([
            makePost(on: day(2026, 8, 10), status: .scheduled),
            makePost(on: day(2026, 8, 10), status: .draft)
        ])
        XCTAssertEqual(makeVM(plan: plan).dayStatus(for: day(2026, 8, 10)), .unpublishedOnly)
    }

    // 18. 投稿済みのみの日
    func testPublishedOnly() {
        let plan = makePlan([makePost(on: day(2026, 8, 10), status: .published)])
        XCTAssertEqual(makeVM(plan: plan).dayStatus(for: day(2026, 8, 10)), .publishedOnly)
    }

    // 19. 状態混在の日
    func testMixedStatus() {
        let plan = makePlan([
            makePost(on: day(2026, 8, 10), status: .scheduled),
            makePost(on: day(2026, 8, 10), status: .published)
        ])
        XCTAssertEqual(makeVM(plan: plan).dayStatus(for: day(2026, 8, 10)), .mixed)
    }

    // 8/9. 次月移動：今日を含まない月では移動先1日を選択
    func testNextMonthSelectsFirstDay() {
        let vm = makeVM(plan: makePlan([]), now: day(2026, 8, 15))
        vm.goToNextMonth()
        XCTAssertTrue(calendar.isDate(vm.displayedMonth, equalTo: day(2026, 9, 1), toGranularity: .month))
        XCTAssertTrue(vm.selectedDate.isSameDay(as: day(2026, 9, 1)))
    }

    // 前月移動：今日を含む月では今日を選択
    func testPreviousMonthSelectsTodayWhenPresent() {
        let vm = makeVM(plan: makePlan([]), now: day(2026, 8, 15))
        vm.goToNextMonth()      // 9月へ
        vm.goToPreviousMonth()  // 8月へ戻る（今日を含む）
        XCTAssertTrue(vm.selectedDate.isSameDay(as: day(2026, 8, 15)))
    }

    // 20. 投稿日変更後、旧日付から消え新日付に現れる（ロジック）
    func testPostDateChangeReflectsInExtraction() {
        let post = makePost(on: day(2026, 8, 10), status: .scheduled)
        let vm = makeVM(plan: makePlan([post]))
        XCTAssertEqual(vm.posts(on: day(2026, 8, 10)).count, 1)

        // 予定日を変更（編集画面の保存に相当）
        post.scheduledDate = calendar.startOfDay(for: day(2026, 8, 20))

        XCTAssertEqual(vm.posts(on: day(2026, 8, 10)).count, 0)
        XCTAssertEqual(vm.posts(on: day(2026, 8, 20)).count, 1)
    }

    // 21. 既存投稿を複製しない
    func testDoesNotDuplicatePosts() {
        let plan = makePlan([
            makePost(on: day(2026, 8, 10), status: .scheduled),
            makePost(on: day(2026, 8, 11), status: .published)
        ])
        let vm = makeVM(plan: plan)
        _ = vm.days
        _ = vm.posts(on: day(2026, 8, 10))
        _ = vm.dayStatus(for: day(2026, 8, 11))
        XCTAssertEqual(plan.posts.count, 2)
    }

    // 22. 再読み込み相当でも件数が変わらない
    func testRepeatedReadsKeepCountStable() {
        let plan = makePlan([makePost(on: day(2026, 8, 10), status: .scheduled)])
        let vm = makeVM(plan: plan)
        for _ in 0..<5 {
            _ = vm.days
            _ = vm.selectedDatePosts
            _ = vm.postCount(on: day(2026, 8, 10))
        }
        XCTAssertEqual(plan.posts.count, 1)
    }

    // 23. 年月タイトルが日本語
    func testMonthTitleJapanese() {
        let vm = makeVM(plan: makePlan([]), now: day(2026, 8, 1))
        XCTAssertTrue(vm.monthTitle.contains("年"))
        XCTAssertTrue(vm.monthTitle.contains("月"))
    }

    // MARK: - Phase 9-4: 今日へ戻る

    // 過去月表示から「今日」で現在月・今日へ戻る
    func testSelectTodayFromPastMonth() {
        let today = day(2026, 7, 23)
        let vm = makeVM(plan: makePlan([]), now: today)
        vm.goToPreviousMonth() // 6月へ
        vm.goToPreviousMonth() // 5月へ
        vm.selectToday()
        XCTAssertTrue(calendar.isDate(vm.displayedMonth, equalTo: today, toGranularity: .month))
        XCTAssertTrue(vm.selectedDate.isSameDay(as: today))
    }

    // 未来月表示から「今日」で現在月・今日へ戻る
    func testSelectTodayFromFutureMonth() {
        let today = day(2026, 7, 23)
        let vm = makeVM(plan: makePlan([]), now: today)
        vm.goToNextMonth() // 8月へ
        vm.goToNextMonth() // 9月へ
        vm.selectToday()
        XCTAssertEqual(calendar.component(.year, from: vm.displayedMonth), 2026)
        XCTAssertEqual(calendar.component(.month, from: vm.displayedMonth), 7)
        XCTAssertTrue(vm.selectedDate.isSameDay(as: today))
    }

    // isViewingToday は今日表示中 true / 月移動後 false
    func testIsViewingToday() {
        let today = day(2026, 7, 23)
        let vm = makeVM(plan: makePlan([]), now: today)
        XCTAssertTrue(vm.isViewingToday) // 初期は今日
        vm.goToNextMonth()
        XCTAssertFalse(vm.isViewingToday)
        vm.selectToday()
        XCTAssertTrue(vm.isViewingToday)
    }

    // 今日へ戻ると選択日の投稿が今日の投稿に一致する
    func testSelectTodayUpdatesSelectedDatePosts() {
        let today = day(2026, 7, 23)
        let plan = makePlan([makePost(on: today, status: .scheduled)])
        let vm = makeVM(plan: plan, now: today)
        vm.goToNextMonth() // 8月（今日の投稿は選択外）
        vm.selectToday()
        XCTAssertEqual(vm.selectedDatePosts.count, 1)
        XCTAssertTrue(vm.selectedDatePosts.first?.scheduledDate.isSameDay(as: today) ?? false)
    }
}
