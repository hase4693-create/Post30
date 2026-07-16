//
//  PostListViewModelTests.swift
//  Post30Tests
//
//  投稿一覧のフィルターが正しく動作することを検証する。
//

import XCTest
@testable import Post30

final class PostListViewModelTests: XCTestCase {

    private let calendar = Calendar.current

    /// 指定ステータス構成の計画を作る。
    private func makePlan(statuses: [PostStatus]) -> MonthPlan {
        let start = calendar.startOfDay(for: Date())
        let plan = MonthPlan(
            title: "テスト計画",
            year: 2026, month: 8,
            startDate: start, endDate: start.adding(days: statuses.count - 1),
            status: .active
        )
        let posts = statuses.enumerated().map { index, status in
            Post(
                scheduledDate: start.adding(days: index),
                platform: .threads,
                category: .other,
                content: "本文\(index)",
                status: status
            )
        }
        plan.addPosts(posts)
        return plan
    }

    // 全件フィルター
    func testAllFilterReturnsEveryPost() {
        let plan = makePlan(statuses: [.published, .scheduled, .draft, .skipped])
        let vm = PostListViewModel(plan: plan)
        vm.selectedFilter = .all
        XCTAssertEqual(vm.filteredPosts.count, 4)
    }

    // 未投稿フィルター（draft + scheduled のみ）
    func testUnpublishedFilter() {
        let plan = makePlan(statuses: [.published, .scheduled, .draft, .skipped])
        let vm = PostListViewModel(plan: plan)
        vm.selectedFilter = .unpublished
        XCTAssertEqual(vm.filteredPosts.count, 2)
        XCTAssertTrue(vm.filteredPosts.allSatisfy { $0.status == .draft || $0.status == .scheduled })
    }

    // 投稿済みフィルター
    func testPublishedFilter() {
        let plan = makePlan(statuses: [.published, .published, .scheduled, .skipped])
        let vm = PostListViewModel(plan: plan)
        vm.selectedFilter = .published
        XCTAssertEqual(vm.filteredPosts.count, 2)
        XCTAssertTrue(vm.filteredPosts.allSatisfy { $0.status == .published })
    }

    // 予定日昇順で並ぶ
    func testPostsAreSortedByScheduledDate() {
        let plan = makePlan(statuses: [.scheduled, .scheduled, .scheduled])
        let vm = PostListViewModel(plan: plan)
        let dates = vm.filteredPosts.map { $0.scheduledDate }
        XCTAssertEqual(dates, dates.sorted(by: <))
    }

    // 計画なし／0件は空
    func testEmptyWhenNoPosts() {
        let vm = PostListViewModel(plan: nil)
        XCTAssertTrue(vm.isEmpty)
        XCTAssertEqual(vm.filteredPosts.count, 0)
    }

    // 編集リクエストで経路が積まれる
    func testRequestEditAppendsRoute() {
        let plan = makePlan(statuses: [.scheduled])
        let vm = PostListViewModel(plan: plan)
        let post = vm.filteredPosts[0]
        vm.requestEdit(post)
        XCTAssertEqual(vm.path, [.edit(post)])
    }
}
