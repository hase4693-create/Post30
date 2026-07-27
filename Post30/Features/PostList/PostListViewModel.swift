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

    /// 一覧のフィルター（投稿の「公開状態」による分類の唯一の基準）。
    /// 判定は永続化された `Post.status` のみに基づき、投稿日と現在日時の比較は一切行わない。
    /// - 未投稿: draft または scheduled（＝まだ投稿処理が完了していない）
    /// - 投稿済み: published（＝実際に投稿済み）
    /// - skipped（見送り）はどちらにも含めない。
    enum Filter: String, CaseIterable, Identifiable, Sendable {
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

        /// 投稿がこのフィルターに一致するか（ステータス基準のみ）。
        func matches(_ post: Post) -> Bool {
            switch self {
            case .all:
                return true
            case .unpublished:
                return post.status == .draft || post.status == .scheduled
            case .published:
                return post.status == .published
            }
        }
    }

    /// 一覧からの遷移経路。
    enum Route: Hashable {
        case edit(Post)
    }

    // MARK: - 依存

    private let plan: MonthPlan?
    private let calendar: Calendar
    /// 表示対象の月に含まれる日を1つ指定すると、その月の投稿だけに絞り込む（nil で全期間）。
    private let monthScope: Date?

    // MARK: - 公開状態

    var selectedFilter: Filter = .all
    var path: [Route] = []

    init(plan: MonthPlan?, monthScope: Date? = nil, calendar: Calendar = .current) {
        self.plan = plan
        self.monthScope = monthScope
        self.calendar = calendar
    }

    // MARK: - データ

    /// 予定日昇順の全投稿。
    private var sortedPosts: [Post] {
        (plan?.posts ?? []).sorted { $0.scheduledDate < $1.scheduledDate }
    }

    /// monthScope が指定されていれば、月初以上・翌月初未満の範囲を返す。
    /// Calendar/Locale/TimeZone を考慮し、失敗時は nil で絞り込みなし。
    var monthInterval: DateInterval? {
        guard let monthScope else { return nil }
        let comps = calendar.dateComponents([.year, .month], from: monthScope)
        guard let start = calendar.date(from: comps),
              let nextStart = calendar.date(byAdding: .month, value: 1, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: nextStart)
    }

    /// 月スコープを適用した対象投稿（分類前）。
    private var scopedPosts: [Post] {
        guard let interval = monthInterval else { return sortedPosts }
        return sortedPosts.filter {
            $0.scheduledDate >= interval.start && $0.scheduledDate < interval.end
        }
    }

    /// フィルター適用後の投稿（月スコープ→公開状態フィルターの順）。
    var filteredPosts: [Post] {
        scopedPosts.filter { selectedFilter.matches($0) }
    }

    /// 対象スコープに投稿が1件もない（計画が空・当月0件など）。
    var isEmpty: Bool {
        scopedPosts.isEmpty
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

    /// 投稿の編集画面へ遷移する（対象 Post を渡す）。
    func requestEdit(_ post: Post) {
        path.append(.edit(post))
    }
}
