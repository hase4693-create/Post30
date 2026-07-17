//
//  MonthPlan.swift
//  Post30
//
//  30日間の投稿運用をまとめて管理する SwiftData モデル。
//
//  設計方針（Phase 7 / SwiftData 移行）:
//  - @Model で永続化。posts は Relationship（cascade 削除）。
//  - 集計は計算プロパティのまま（保存対象にせず、posts から計算）。
//

import Foundation
import SwiftData

@Model
final class MonthPlan {
    @Attribute(.unique) var id: UUID
    var title: String
    var year: Int
    var month: Int
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var updatedAt: Date
    var status: MonthPlanStatus

    /// この計画に属する投稿。親削除時に子も削除（cascade）。
    @Relationship(deleteRule: .cascade, inverse: \Post.plan)
    var posts: [Post]

    init(
        id: UUID = UUID(),
        title: String,
        year: Int,
        month: Int,
        startDate: Date,
        endDate: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        status: MonthPlanStatus = .draft,
        posts: [Post] = []
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.month = month
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.posts = []
        addPosts(posts)
    }

    // MARK: - 親子関係の管理

    /// 投稿を1件追加し、親子関係を整合させる。
    /// コンテキスト内外どちらでも整合するよう、両側を防御的に設定する。
    func addPost(_ post: Post) {
        if post.plan !== self {
            post.plan = self
        }
        if !posts.contains(where: { $0 === post }) {
            posts.append(post)
        }
    }

    func addPosts(_ newPosts: [Post]) {
        newPosts.forEach { addPost($0) }
    }

    /// 投稿配列をメモリ上で置き換える（永続層での旧Post削除は Store 側で行う）。
    func replacePosts(_ newPosts: [Post]) {
        posts.removeAll()
        addPosts(newPosts)
    }

    // MARK: - 集計（計算プロパティ・非永続）

    var totalPostCount: Int { posts.count }

    var publishedCount: Int {
        posts.filter { $0.status == .published }.count
    }

    /// 未投稿件数（draft + scheduled のみ。published/skipped は含めない）。
    var unpublishedCount: Int {
        posts.filter { $0.status == .draft || $0.status == .scheduled }.count
    }

    /// 投稿完了率（投稿済み ÷ 総数、0.0〜1.0）。0件でもゼロ除算しない。
    /// - Note: published のみを完了として数える（将来 processedProgressRate を追加可能）。
    var publishedProgressRate: Double {
        guard totalPostCount > 0 else { return 0 }
        return Double(publishedCount) / Double(totalPostCount)
    }

    // MARK: - 取得ロジック

    func posts(on date: Date, calendar: Calendar = .current) -> [Post] {
        posts.filter { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    func nextScheduledPost(after date: Date = Date(), calendar: Calendar = .current) -> Post? {
        let threshold = calendar.startOfDay(for: date)
        return posts
            .filter { $0.status == .scheduled && $0.scheduledDate >= threshold }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }
}
