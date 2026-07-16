//
//  SampleData.swift
//  Post30
//
//  Preview / Unit Test 用のサンプルデータ。
//  30件の投稿は手書きで重複記述せず、生成ヘルパーで作る。
//  （AIによる投稿生成機能ではない。固定テンプレートの機械的な組み立て。）
//

import Foundation

enum SampleData {

    // MARK: - 基準日

    /// サンプルの基準日。テストの再現性のため固定値を用いる。
    /// 2026-08-01 00:00（現地カレンダー）。
    static let referenceDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }()

    // MARK: - 公開サンプル

    /// 投稿30件を持つ進行中のMonthPlan。
    static func activePlanWith30Posts() -> MonthPlan {
        let start = referenceDate
        let end = start.adding(days: 29)
        let plan = MonthPlan(
            title: "2026年8月の投稿計画",
            year: 2026,
            month: 8,
            startDate: start,
            endDate: end,
            status: .active
        )
        plan.addPosts(makePosts(count: 30, startDate: start))
        return plan
    }

    /// 投稿が0件のMonthPlan。
    static func emptyPlan() -> MonthPlan {
        let start = referenceDate
        return MonthPlan(
            title: "2026年9月の投稿計画（未作成）",
            year: 2026,
            month: 9,
            startDate: start,
            endDate: start.adding(days: 29),
            status: .draft
        )
    }

    /// 完了済みのMonthPlan（全件が投稿済み）。
    static func completedPlan() -> MonthPlan {
        let start = referenceDate.adding(days: -30)
        let plan = MonthPlan(
            title: "2026年7月の投稿計画",
            year: 2026,
            month: 7,
            startDate: start,
            endDate: start.adding(days: 29),
            status: .completed
        )
        var posts = makePosts(count: 30, startDate: start)
        for (index, post) in posts.enumerated() {
            post.status = .published
            post.publishedAt = start.adding(days: index)
        }
        plan.addPosts(posts)
        return plan
    }

    /// 今日投稿予定のPost。
    static func todayScheduledPost() -> Post {
        Post(
            scheduledDate: Date(),
            scheduledTime: DateComponents(hour: 8, minute: 0),
            platform: .threads,
            category: .empathy,
            content: "朝の30分を自分のために使うと、一日の見え方が変わります。今日はどんな時間を大切にしますか？",
            status: .scheduled
        )
    }

    /// 投稿済みのPost。
    static func publishedPost() -> Post {
        Post(
            scheduledDate: Date().adding(days: -1),
            scheduledTime: DateComponents(hour: 19, minute: 0),
            platform: .threads,
            category: .knowHow,
            content: "投稿を続けるコツは「完璧を目指さないこと」。60点で出し続けるほうが、100点を狙って止まるより伸びます。",
            status: .published,
            publishedAt: Date().adding(days: -1)
        )
    }

    /// 見送りのPost。
    static func skippedPost() -> Post {
        Post(
            scheduledDate: Date().adding(days: -2),
            platform: .threads,
            category: .promotion,
            content: "（この日はキャンペーン準備のため投稿を見送り）",
            status: .skipped
        )
    }

    // MARK: - 生成ヘルパー

    /// 指定件数の投稿を生成する。
    /// カテゴリを循環させ、本文はテンプレートから機械的に組み立てる。
    static func makePosts(count: Int, startDate: Date) -> [Post] {
        (0..<count).map { index in
            let category = categoryCycle[index % categoryCycle.count]
            let date = startDate.adding(days: index)
            // 前半は投稿予定、直近の一部は投稿済みにして状態を混在させる。
            let status: PostStatus = index < 3 ? .published : .scheduled
            return Post(
                scheduledDate: date,
                scheduledTime: DateComponents(hour: 8, minute: 0),
                platform: .threads,
                category: category,
                content: bodyTemplate(day: index + 1, category: category),
                status: status,
                publishedAt: status == .published ? date : nil
            )
        }
    }

    // MARK: - テンプレート

    /// カテゴリの循環順（8種）。
    private static let categoryCycle: [PostCategory] = [
        .empathy, .knowHow, .experience, .failure,
        .promotion, .question, .achievement, .other
    ]

    /// 日番号とカテゴリから本文を組み立てる。
    private static func bodyTemplate(day: Int, category: PostCategory) -> String {
        "【\(day)日目・\(category.displayName)】\(categoryLead[category] ?? "今日の投稿です。")"
    }

    /// カテゴリごとの日本語リード文。
    private static let categoryLead: [PostCategory: String] = [
        .empathy: "頑張っているのに成果が見えない時期は、誰にでもあります。まずは続けている自分を認めましょう。",
        .knowHow: "投稿の反応を上げる小さなコツを1つ。冒頭の一文で「誰への話か」を明確にすると読まれやすくなります。",
        .experience: "副業を始めた頃、最初の1件が来るまで3週間かかりました。その間にやっていたことを共有します。",
        .failure: "以前、宣伝ばかりして反応が激減しました。学びは「与える投稿と告知の比率」でした。",
        .promotion: "新しいメニューのご案内です。詳細はプロフィールのリンクからご覧いただけます。",
        .question: "みなさんは投稿を作る時間、いつ確保していますか？ おすすめの習慣があれば教えてください。",
        .achievement: "先月の投稿からお問い合わせが5件に増えました。継続の成果を少しずつ実感しています。",
        .other: "今日は少し肩の力を抜いた投稿を。日々の運用の中で感じたことを書いていきます。"
    ]
}
