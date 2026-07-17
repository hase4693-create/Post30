//
//  PersistenceStore.swift
//  Post30
//
//  SwiftData へのアクセスを集約する最小限のデータストア。
//  ModelContext を各 View へ直接渡さず、保存・取得・置換・削除・シードをここに集める。
//  保存エラーは throw で伝播し、握りつぶさない。
//

import Foundation
import SwiftData

@MainActor
final class PersistenceStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - 取得

    /// 最新の（createdAt 降順で先頭の）MonthPlan を返す。
    func currentMonthPlan() throws -> MonthPlan? {
        var descriptor = FetchDescriptor<MonthPlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func monthPlanCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<MonthPlan>())
    }

    func postCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<Post>())
    }

    // MARK: - 保存

    /// 変更を永続化する。
    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    // MARK: - 作成 / 追加

    /// MonthPlan をコンテキストへ挿入して保存する。
    @discardableResult
    func insertMonthPlan(_ plan: MonthPlan) throws -> MonthPlan {
        context.insert(plan)
        try save()
        return plan
    }

    /// 空の MonthPlan（投稿0件）を作成して保存する。
    @discardableResult
    func createEmptyMonthPlan(now: Date = Date(), calendar: Calendar = .current) throws -> MonthPlan {
        let comps = calendar.dateComponents([.year, .month], from: now)
        let plan = MonthPlan(
            title: "\(comps.year ?? 0)年\(comps.month ?? 0)月の投稿計画",
            year: comps.year ?? 0,
            month: comps.month ?? 0,
            startDate: calendar.startOfDay(for: now),
            endDate: calendar.startOfDay(for: now),
            status: .draft
        )
        return try insertMonthPlan(plan)
    }

    /// 投稿を計画へ追加して保存する。
    func addPost(_ post: Post, to plan: MonthPlan) throws {
        context.insert(post)
        plan.addPost(post)
        try save()
    }

    // MARK: - 置き換え（旧Postを孤立させない）

    /// 計画の投稿をすべて削除し、新しい投稿へ置き換えて保存する。
    func replacePosts(in plan: MonthPlan, with newPosts: [Post]) throws {
        for old in plan.posts {
            context.delete(old)
        }
        plan.posts.removeAll()
        for post in newPosts {
            context.insert(post)
            plan.addPost(post)
        }
        try save()
    }

    // MARK: - 削除

    /// 計画を削除する（cascade により所属Postも削除）。
    func delete(_ plan: MonthPlan) throws {
        context.delete(plan)
        try save()
    }

    // MARK: - 初回シード

    /// データが空のときだけ、動作確認用の MonthPlan を1件投入する。
    /// 既にデータがあれば何もしない（起動のたびに増えない）。
    func seedIfNeeded() throws {
        guard try monthPlanCount() == 0 else { return }
        let plan = SampleData.activePlanWith30Posts()
        context.insert(plan)
        try save()
    }
}
