//
//  PostListPreviewData.swift
//  Post30
//
//  投稿一覧 Preview 専用データ（DEBUG 限定・本番 SampleData とは分離）。
//

#if DEBUG
import Foundation

enum PostListPreviewData {

    private static let calendar = Calendar.current
    private static let categories: [PostCategory] = [
        .empathy, .knowHow, .experience, .failure,
        .promotion, .question, .achievement, .other
    ]

    /// 30件（前半=投稿済み、一部=見送り、残り=予定）を持つ計画を生成する。
    private static func plan30() -> MonthPlan {
        let start = calendar.startOfDay(for: Date())
        let plan = MonthPlan(
            title: "プレビュー用の計画",
            year: 2026, month: 8,
            startDate: start, endDate: start.adding(days: 29),
            status: .active
        )
        let posts = (0..<30).map { index -> Post in
            let category = categories[index % categories.count]
            let status: PostStatus
            switch index {
            case 0..<10: status = .published
            case 10..<12: status = .skipped
            default: status = .scheduled
            }
            return Post(
                scheduledDate: start.adding(days: index),
                scheduledTime: DateComponents(hour: 8, minute: 0),
                platform: .threads,
                category: category,
                content: "【\(index + 1)日目・\(category.displayName)】プレビュー用の投稿本文です。一覧セルでの表示確認に使います。",
                status: status,
                publishedAt: status == .published ? start.adding(days: index) : nil
            )
        }
        plan.addPosts(posts)
        return plan
    }

    static func viewModel(filter: PostListViewModel.Filter) -> PostListViewModel {
        let vm = PostListViewModel(plan: plan30())
        vm.selectedFilter = filter
        return vm
    }

    static func emptyViewModel() -> PostListViewModel {
        let start = calendar.startOfDay(for: Date())
        let plan = MonthPlan(
            title: "空の計画",
            year: 2026, month: 9,
            startDate: start, endDate: start.adding(days: 29),
            status: .draft
        )
        return PostListViewModel(plan: plan)
    }
}
#endif
