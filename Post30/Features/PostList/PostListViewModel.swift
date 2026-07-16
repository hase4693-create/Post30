//
//  PostListViewModel.swift
//  Post30
//
//  投稿一覧画面のロジック（MVVM）。フィルター切替と表示整形を担う。
//  検索はUIのみで、絞り込みロジックは持たない（将来用）。
//

import Foundation
import Observation

@Observable
final class PostListViewModel {

    /// 一覧のフィルター。
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case unpublished
        case published

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .all: return "すべて"
            case .unpublished: return "未投稿"
            case .published: return "投稿済み"
            }
        }
    }

    /// 一覧からの遷移経路。
    enum Route: Hashable {
        case edit(Post)
        case generate
    }

    // MARK: - 依存

    private let plan: MonthPlan?
    private let calendar: Calendar

    // MARK: - 公開状態

    var selectedFilter: Filter = .all
    /// 検索テキスト（今回はUIのみ・絞り込みには未使用）。
    var searchText: String = ""
    var path: [Route] = []

    init(plan: MonthPlan?, calendar: Calendar = .current) {
        self.plan = plan
        self.calendar = calendar
    }

    // MARK: - データ

    /// 予定日昇順の全投稿。
    private var sortedPosts: [Post] {
        (plan?.posts ?? []).sorted { $0.scheduledDate < $1.scheduledDate }
    }

    /// フィルター適用後の投稿。
    var filteredPosts: [Post] {
        switch selectedFilter {
        case .all:
            return sortedPosts
        case .unpublished:
            return sortedPosts.filter { $0.status == .draft || $0.status == .scheduled }
        case .published:
            return sortedPosts.filter { $0.status == .published }
        }
    }

    /// 投稿が1件もない（計画が空 or なし）。
    var isEmpty: Bool {
        sortedPosts.isEmpty
    }

    /// 総投稿数。
    var totalPostCount: Int {
        sortedPosts.count
    }

    // MARK: - 表示整形

    /// 予定日テキスト（例: 7月15日(水)）。
    func scheduledDateText(for post: Post) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
        return formatter.string(from: post.scheduledDate)
    }

    // MARK: - アクション

    /// 投稿の編集プレースホルダへ遷移する（対象 Post を渡す）。
    func requestEdit(_ post: Post) {
        path.append(.edit(post))
    }

    /// 30日分生成プレースホルダへ遷移する。
    func requestGenerate() {
        path.append(.generate)
    }
}
