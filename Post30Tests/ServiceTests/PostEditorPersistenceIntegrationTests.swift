//
//  PostEditorPersistenceIntegrationTests.swift
//  Post30Tests
//
//  実際の保存経路（PostEditorViewModel → PersistenceStore → SwiftData）を通す統合テスト。
//  「投稿日の変更だけでは status が変わらない」ことを、本番と同じ経路・再取得で検証する。
//

import XCTest
import SwiftData
@testable import Post30

@MainActor
final class PostEditorPersistenceIntegrationTests: XCTestCase {

    private let calendar = Calendar.current

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: MonthPlan.self, Post.self, configurations: config)
    }

    /// scheduled 投稿の投稿日を未来→過去へ変更して保存しても、
    /// 別コンテキストで再取得したときに status=scheduled / publishedAt=nil のままであること。
    func testEditingDateThroughRealPathKeepsScheduled() throws {
        let container = try makeContainer()
        let writeStore = PersistenceStore(context: ModelContext(container))

        // 1. scheduled（未投稿）投稿を SwiftData へ保存（未来日）
        let futureDate = calendar.date(byAdding: .day, value: 30, to: Date())!
        let post = Post(
            scheduledDate: futureDate,
            scheduledTime: DateComponents(hour: 8, minute: 0),
            platform: .threads, category: .other,
            content: "未投稿の本文", status: .scheduled, publishedAt: nil
        )
        let plan = MonthPlan(
            title: "計画", year: 2026, month: 8,
            startDate: futureDate, endDate: futureDate, status: .active,
            posts: [post]
        )
        try writeStore.insertMonthPlan(plan)

        // 2. 実際の EditorViewModel から読み込む
        let editor = PostEditorViewModel(post: post, store: writeStore)

        // 3. 日付だけを過去日へ変更
        let pastDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        editor.scheduledDate = pastDate

        // 4. 実際の保存処理
        let didSave = editor.save()
        XCTAssertTrue(didSave)

        // 6. 別コンテキスト（Store 再生成＝再起動相当）で再取得
        let readStore = PersistenceStore(context: ModelContext(container))
        let reloaded = try readStore.currentMonthPlan()?.posts.first

        // 7. status は scheduled のまま・publishedAt は nil のまま
        XCTAssertEqual(reloaded?.status, .scheduled)
        XCTAssertNil(reloaded?.publishedAt)
        // 予定日は過去日へ更新されている
        XCTAssertTrue(reloaded?.scheduledDate.isSameDay(as: pastDate) ?? false)

        // 8〜10. 一覧 ViewModel で未投稿に含まれ、投稿済みに含まれない
        guard let reloadedPlan = try readStore.currentMonthPlan() else {
            return XCTFail("計画が取得できない")
        }
        let listVM = PostListViewModel(plan: reloadedPlan)
        listVM.selectedFilter = .unpublished
        XCTAssertEqual(listVM.filteredPosts.count, 1)
        listVM.selectedFilter = .published
        XCTAssertEqual(listVM.filteredPosts.count, 0)
    }

    /// 正式な投稿完了（markAsPublished 相当）を通したときのみ published になることの対比確認。
    func testOnlyPublishFlowChangesStatus() throws {
        let container = try makeContainer()
        let store = PersistenceStore(context: ModelContext(container))
        let post = Post(scheduledDate: Date(), platform: .threads, category: .other,
                        content: "本文", status: .scheduled, publishedAt: nil)
        let plan = MonthPlan(title: "計画", year: 2026, month: 8,
                             startDate: Date(), endDate: Date(), posts: [post])
        try store.insertMonthPlan(plan)

        // 日付編集では変わらない
        let editor = PostEditorViewModel(post: post, store: store)
        editor.scheduledDate = calendar.date(byAdding: .day, value: -10, to: Date())!
        _ = editor.save()
        XCTAssertEqual(post.status, .scheduled)

        // 正式な投稿完了処理でのみ published になる
        let home = HomeViewModel(plan: plan, clipboardService: NoopClipboard(), store: store)
        home.markAsPublished(post)
        XCTAssertEqual(post.status, .published)
        XCTAssertNotNil(post.publishedAt)
    }

    // Phase 9-2: 編集画面の「投稿済みにする」を本番経路で実行し、再取得後も維持されること。
    func testMarkAsPublishedThroughRealPathPersists() throws {
        let container = try makeContainer()
        let writeStore = PersistenceStore(context: ModelContext(container))

        let post = Post(
            scheduledDate: calendar.date(byAdding: .day, value: -3, to: Date())!,
            scheduledTime: DateComponents(hour: 8, minute: 0),
            platform: .threads, category: .other,
            content: "元の本文", status: .scheduled, publishedAt: nil
        )
        let plan = MonthPlan(
            title: "計画", year: 2026, month: 8,
            startDate: Date(), endDate: Date(), status: .active, posts: [post]
        )
        try writeStore.insertMonthPlan(plan)

        // 編集画面相当：本文を編集し、投稿済みにする
        let editor = PostEditorViewModel(post: post, store: writeStore)
        editor.content = "編集して投稿済みにした本文"
        let ok = editor.confirmMarkAsPublished()
        XCTAssertTrue(ok)

        // 別コンテキスト（再起動相当）で再取得
        let readStore = PersistenceStore(context: ModelContext(container))
        let reloaded = try readStore.currentMonthPlan()?.posts.first
        XCTAssertEqual(reloaded?.status, .published)
        XCTAssertNotNil(reloaded?.publishedAt)
        XCTAssertEqual(reloaded?.content, "編集して投稿済みにした本文")

        // 一覧分類でも投稿済みに含まれ、未投稿に含まれない
        guard let reloadedPlan = try readStore.currentMonthPlan() else {
            return XCTFail("計画が取得できない")
        }
        let listVM = PostListViewModel(plan: reloadedPlan)
        listVM.selectedFilter = .published
        XCTAssertEqual(listVM.filteredPosts.count, 1)
        listVM.selectedFilter = .unpublished
        XCTAssertEqual(listVM.filteredPosts.count, 0)
    }

    private struct NoopClipboard: ClipboardService {
        func copy(_ text: String) {}
    }
}
