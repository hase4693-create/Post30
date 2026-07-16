//
//  MonthPlan.swift
//  Post30
//
//  30日間の投稿運用をまとめて管理する月次計画モデル。
//
//  設計方針:
//  - 現段階では SwiftData マクロ(@Model)は使用しない（Phase 8 で導入予定）。
//  - posts は private(set) とし、addPost 経由でのみ追加することで、
//    子(Post)から親(MonthPlan)への逆参照(plan)を常に整合させる。
//  - 進捗率などの表示ロジックは計算プロパティで提供し、
//    表示用文字列をモデルへ過剰に持たせない。
//

import Foundation

/// 30日間の投稿運用計画。
final class MonthPlan: Identifiable {
    /// 一意な識別子。
    let id: UUID
    /// 計画名。
    var title: String
    /// 対象の年。
    var year: Int
    /// 対象の月。
    var month: Int
    /// 運用開始日。
    var startDate: Date
    /// 運用終了日。
    var endDate: Date
    /// 作成日時。
    var createdAt: Date
    /// 更新日時。
    var updatedAt: Date
    /// ステータス。
    var status: MonthPlanStatus

    /// この計画に属する投稿。追加は addPost / addPosts を用いる。
    private(set) var posts: [Post]

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
        // 逆参照を整合させながら追加する。
        addPosts(posts)
    }

    // MARK: - 親子関係の管理

    /// 投稿を1件追加し、所属(monthPlanID)を設定する（単方向参照）。
    func addPost(_ post: Post) {
        post.monthPlanID = id
        posts.append(post)
    }

    /// 投稿を複数追加する。
    func addPosts(_ newPosts: [Post]) {
        newPosts.forEach { addPost($0) }
    }

    /// 既存の投稿をすべて置き換える（生成結果の反映に使用）。
    /// 各 Post の monthPlanID もこの計画に更新される。
    func replacePosts(_ newPosts: [Post]) {
        posts.removeAll()
        addPosts(newPosts)
    }

    // MARK: - 集計（計算プロパティ）

    /// 総投稿数。
    var totalPostCount: Int {
        posts.count
    }

    /// 投稿済み件数。
    var publishedCount: Int {
        posts.filter { $0.status == .published }.count
    }

    /// 未投稿件数。
    /// 「これから投稿する予定のもの」= draft と scheduled のみを数える。
    /// published（投稿済み）と skipped（見送り）は含めない。
    var unpublishedCount: Int {
        posts.filter { $0.status == .draft || $0.status == .scheduled }.count
    }

    /// 投稿完了率（投稿済み件数 ÷ 総投稿数、0.0〜1.0）。
    /// 総投稿数が0件でもゼロ除算せず 0 を返す。
    ///
    /// - Note: ここでの「完了」は published（投稿済み）のみを指す。
    ///   将来、published + skipped を「処理済み」として扱う
    ///   processedProgressRate を別途追加できるよう、名称に published を明示している
    ///   （今回はその新プロパティは追加しない）。
    var publishedProgressRate: Double {
        guard totalPostCount > 0 else { return 0 }
        return Double(publishedCount) / Double(totalPostCount)
    }

    // MARK: - 取得ロジック

    /// 指定日に予定されている投稿を返す（日単位で比較）。
    func posts(on date: Date, calendar: Calendar = .current) -> [Post] {
        posts.filter { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    /// 基準日以降で次に投稿予定（status == .scheduled）の投稿を返す。
    /// 予定日が早い順で最初の1件。該当がなければ nil。
    func nextScheduledPost(after date: Date = Date(), calendar: Calendar = .current) -> Post? {
        let threshold = calendar.startOfDay(for: date)
        return posts
            .filter { $0.status == .scheduled && $0.scheduledDate >= threshold }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .first
    }
}
