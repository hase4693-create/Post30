//
//  HomePreviewData.swift
//  Post30
//
//  ホーム画面 Preview 専用データ。
//  本番の SampleData とは混在させず、この DEBUG 限定データのみを Preview で使う。
//

#if DEBUG
import Foundation

@MainActor
enum HomePreviewData {

    /// Preview 用の何もしないクリップボード実装。
    struct NoopClipboardService: ClipboardService {
        func copy(_ text: String) {}
    }

    private static let calendar = Calendar.current

    private static func makePost(
        dayOffset: Int,
        hour: Int = 8,
        minute: Int = 0,
        category: PostCategory,
        content: String,
        status: PostStatus
    ) -> Post {
        let base = calendar.startOfDay(for: Date())
        return Post(
            scheduledDate: base.adding(days: dayOffset),
            scheduledTime: DateComponents(hour: hour, minute: minute),
            platform: .threads,
            category: category,
            content: content,
            status: status,
            publishedAt: status == .published ? base.adding(days: dayOffset) : nil
        )
    }

    // MARK: - 1. 今日の投稿あり

    static func viewModelWithTodayPost() -> HomeViewModel {
        let plan = MonthPlan(
            title: "プレビュー用の計画",
            year: 2026, month: 8,
            startDate: Date(), endDate: Date().adding(days: 29),
            status: .active
        )
        plan.addPosts([
            makePost(dayOffset: -2, category: .knowHow, content: "過去の投稿（投稿済み）", status: .published),
            makePost(dayOffset: -1, category: .experience, content: "過去の投稿（投稿済み）", status: .published),
            makePost(dayOffset: 0, category: .empathy,
                     content: "朝の30分を自分のために使うと、一日の見え方が変わります。今日はどんな時間を大切にしますか？",
                     status: .scheduled),
            makePost(dayOffset: 1, category: .question, content: "明日の投稿", status: .scheduled)
        ])
        return HomeViewModel(plan: plan, clipboardService: NoopClipboardService())
    }

    // MARK: - 2. 今日の投稿なし・次回投稿あり

    static func viewModelWithNextPostOnly() -> HomeViewModel {
        let plan = MonthPlan(
            title: "プレビュー用の計画",
            year: 2026, month: 8,
            startDate: Date(), endDate: Date().adding(days: 29),
            status: .active
        )
        plan.addPosts([
            makePost(dayOffset: 2, category: .knowHow,
                     content: "2日後に投稿予定の内容です。次回予定として表示されます。", status: .scheduled),
            makePost(dayOffset: 4, category: .promotion, content: "さらに先の投稿", status: .scheduled)
        ])
        return HomeViewModel(plan: plan, clipboardService: NoopClipboardService())
    }

    // MARK: - 3. 計画なし

    static func viewModelWithNoPlan() -> HomeViewModel {
        HomeViewModel(plan: nil, clipboardService: NoopClipboardService())
    }

    // MARK: - 4. 投稿0件

    static func viewModelWithZeroPosts() -> HomeViewModel {
        let plan = MonthPlan(
            title: "空の計画",
            year: 2026, month: 9,
            startDate: Date(), endDate: Date().adding(days: 29),
            status: .draft
        )
        return HomeViewModel(plan: plan, clipboardService: NoopClipboardService())
    }
}
#endif
