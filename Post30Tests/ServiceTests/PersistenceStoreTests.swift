//
//  PersistenceStoreTests.swift
//  Post30Tests
//
//  SwiftData 永続化の検証。インメモリ ModelContainer を使用する。
//

import XCTest
import SwiftData
@testable import Post30

@MainActor
final class PersistenceStoreTests: XCTestCase {

    private let calendar = Calendar.current

    /// インメモリのコンテナと、そこに紐づくストアを作る。
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: MonthPlan.self, Post.self, configurations: config)
    }

    private func makePlan(postStatuses: [PostStatus] = []) -> MonthPlan {
        let start = calendar.startOfDay(for: Date())
        let plan = MonthPlan(
            title: "テスト計画", year: 2026, month: 8,
            startDate: start, endDate: start.adding(days: 29), status: .active
        )
        let posts = postStatuses.enumerated().map { index, status in
            Post(
                scheduledDate: start.adding(days: index),
                scheduledTime: DateComponents(hour: 8, minute: 0),
                platform: .threads, category: .other,
                content: "本文\(index)", status: status
            )
        }
        plan.addPosts(posts)
        return plan
    }

    // 1. MonthPlan を保存できる
    func testInsertMonthPlan() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))
        try store.insertMonthPlan(makePlan())
        XCTAssertEqual(try store.monthPlanCount(), 1)
    }

    // 2. 保存した MonthPlan を取得できる
    func testFetchCurrentMonthPlan() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))
        try store.insertMonthPlan(makePlan())
        XCTAssertNotNil(try store.currentMonthPlan())
    }

    // 3. Post を保存できる / 4. 関係が保存される
    func testInsertPostAndRelationship() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))
        let plan = try store.insertMonthPlan(makePlan())
        let post = Post(scheduledDate: Date(), content: "追加投稿", status: .scheduled)
        try store.addPost(post, to: plan)

        XCTAssertEqual(try store.postCount(), 1)
        let fetched = try store.currentMonthPlan()
        XCTAssertEqual(fetched?.posts.count, 1)
        XCTAssertTrue(fetched?.posts.first?.plan === fetched)
    }

    // 5. 投稿編集内容が保存される / 6. status / 7. publishedAt
    func testEditPersisted() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))
        let plan = makePlan(postStatuses: [.scheduled])
        try store.insertMonthPlan(plan)

        let post = plan.posts[0]
        post.content = "編集後の本文"
        post.status = .published
        let published = Date(timeIntervalSince1970: 1_800_000_000)
        post.publishedAt = published
        try store.save()

        let fetched = try store.currentMonthPlan()?.posts.first
        XCTAssertEqual(fetched?.content, "編集後の本文")
        XCTAssertEqual(fetched?.status, .published)
        XCTAssertEqual(fetched?.publishedAt, published)
    }

    // 8. replacePosts で旧投稿が残らない
    func testReplacePostsRemovesOld() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))
        let plan = makePlan(postStatuses: [.scheduled, .scheduled, .scheduled])
        try store.insertMonthPlan(plan)
        XCTAssertEqual(try store.postCount(), 3)

        let newPosts = [
            Post(scheduledDate: Date(), content: "新1", status: .scheduled),
            Post(scheduledDate: Date(), content: "新2", status: .scheduled)
        ]
        try store.replacePosts(in: plan, with: newPosts)

        XCTAssertEqual(try store.postCount(), 2)
        XCTAssertEqual(try store.currentMonthPlan()?.posts.count, 2)
    }

    // 9. MonthPlan 削除で所属 Post も削除される
    func testDeleteCascades() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))
        let plan = makePlan(postStatuses: [.scheduled, .scheduled])
        try store.insertMonthPlan(plan)
        XCTAssertEqual(try store.postCount(), 2)

        try store.delete(plan)
        XCTAssertEqual(try store.monthPlanCount(), 0)
        XCTAssertEqual(try store.postCount(), 0)
    }

    // 10. データ0件時だけシードされる / 11. 2回シードしても重複しない
    func testSeedOnlyWhenEmpty() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))

        try store.seedIfNeeded()
        XCTAssertEqual(try store.monthPlanCount(), 1)

        try store.seedIfNeeded()
        XCTAssertEqual(try store.monthPlanCount(), 1, "2回目のシードで重複してはいけない")
    }

    // 12/13. 別の ModelContext から同じデータを取得できる（再起動相当）
    func testDataVisibleFromAnotherContext() throws {
        let container = try makeContainer()

        let writeStore = PersistenceStore(context: ModelContext(container))
        try writeStore.insertMonthPlan(makePlan(postStatuses: [.scheduled, .published]))

        // 同じコンテナの別コンテキスト（再起動時の新しいコンテキストに相当）
        let readStore = PersistenceStore(context: ModelContext(container))
        XCTAssertEqual(try readStore.monthPlanCount(), 1)
        XCTAssertEqual(try readStore.currentMonthPlan()?.posts.count, 2)
    }
}
