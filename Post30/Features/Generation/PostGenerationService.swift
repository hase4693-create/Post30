//
//  PostGenerationService.swift
//  Post30
//
//  投稿生成サービス。今回は AI に接続せず、ローカルのモック生成を行う。
//  待機時間は注入可能で、テスト/Preview では 0 にできる。
//

import Foundation

/// 投稿生成サービスのインターフェース。
protocol PostGenerationService {
    /// 条件から投稿を生成する。1件生成するごとに onProgress(件数) を呼ぶ。
    /// キャンセル時は CancellationError を投げる。
    func generatePosts(
        request: PostGenerationRequest,
        onProgress: @escaping (Int) -> Void
    ) async throws -> [Post]
}

/// ローカルのモック実装（AI 非接続）。
final class MockPostGenerationService: PostGenerationService {

    /// 1件あたりの疑似待機（ナノ秒）。テスト/Preview では 0 を渡す。
    private let perPostDelayNanoseconds: UInt64

    init(perPostDelayNanoseconds: UInt64 = 40_000_000) {
        self.perPostDelayNanoseconds = perPostDelayNanoseconds
    }

    /// カテゴリー配分の基準比率（合計30）。
    static let baseRatios: [(category: PostCategory, ratio: Int)] = [
        (.empathy, 6), (.knowHow, 6), (.experience, 5), (.failure, 4),
        (.promotion, 3), (.question, 3), (.achievement, 3)
    ]

    func generatePosts(
        request: PostGenerationRequest,
        onProgress: @escaping (Int) -> Void
    ) async throws -> [Post] {
        let calendar = Calendar.current
        let categories = Self.arrangedCategories(count: request.postCount)
        let startDay = calendar.startOfDay(for: request.startDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: request.scheduledTime)

        var posts: [Post] = []
        posts.reserveCapacity(request.postCount)

        for index in 0..<request.postCount {
            try Task.checkCancellation()
            if perPostDelayNanoseconds > 0 {
                try await Task.sleep(nanoseconds: perPostDelayNanoseconds)
            }

            let category = categories[index]
            let date = calendar.date(byAdding: .day, value: index, to: startDay) ?? startDay
            let now = Date()
            let post = Post(
                scheduledDate: date,
                scheduledTime: DateComponents(hour: timeComponents.hour, minute: timeComponents.minute),
                platform: request.platform,
                category: category,
                content: Self.body(day: index + 1, category: category, request: request),
                status: .scheduled,
                createdAt: now,
                updatedAt: now,
                memo: nil
            )
            posts.append(post)
            onProgress(posts.count)
        }
        return posts
    }

    // MARK: - カテゴリー配分

    /// 指定件数のカテゴリー目標数（最大剰余法で比率を保つ）。
    static func targetCounts(for total: Int) -> [(category: PostCategory, count: Int)] {
        var counts: [(category: PostCategory, count: Int)] = []
        var fractions: [(index: Int, frac: Double)] = []
        var assigned = 0

        for (i, item) in baseRatios.enumerated() {
            let exact = Double(item.ratio) / 30.0 * Double(total)
            let floored = Int(exact.rounded(.down))
            counts.append((item.category, floored))
            fractions.append((i, exact - Double(floored)))
            assigned += floored
        }

        var remainder = total - assigned
        for (index, _) in fractions.sorted(by: { $0.frac > $1.frac }) where remainder > 0 {
            counts[index].count += 1
            remainder -= 1
        }
        return counts
    }

    /// 同じカテゴリーが連続しないように並べたカテゴリー列を返す。
    static func arrangedCategories(count: Int) -> [PostCategory] {
        let order = baseRatios.map { $0.category }
        var remaining: [PostCategory: Int] = [:]
        for item in targetCounts(for: count) {
            remaining[item.category] = item.count
        }

        var result: [PostCategory] = []
        var last: PostCategory?

        for _ in 0..<count {
            let available = order
                .filter { (remaining[$0] ?? 0) > 0 }
                .sorted { (remaining[$0] ?? 0) > (remaining[$1] ?? 0) }
            guard !available.isEmpty else { break }
            let pick = available.first(where: { $0 != last }) ?? available[0]
            result.append(pick)
            remaining[pick, default: 0] -= 1
            last = pick
        }
        return result
    }

    // MARK: - モック本文

    /// 業種・サービス・ターゲット・カテゴリーを反映した日本語本文を作る。
    /// 先頭に「【N日目・カテゴリー名】」を付けるため、全件が異なる本文になる。
    static func body(day: Int, category: PostCategory, request: PostGenerationRequest) -> String {
        let service = request.serviceName.isEmpty ? "サービス" : request.serviceName
        let target = request.targetAudience.isEmpty ? "お客さま" : request.targetAudience
        let business = request.businessType.isEmpty ? "事業" : request.businessType

        let variants = templates(for: category)
        let base = variants[(day - 1) % variants.count]
            .replacingOccurrences(of: "{service}", with: service)
            .replacingOccurrences(of: "{target}", with: target)
            .replacingOccurrences(of: "{business}", with: business)

        return "【\(day)日目・\(category.displayName)】\n\(base)"
    }

    private static func templates(for category: PostCategory) -> [String] {
        switch category {
        case .empathy:
            return [
                "SNS投稿を続けたいと思っていても、毎回ゼロから考えるのは大変です。まずはテーマを先に決めるだけでも、発信はずっと続けやすくなります。",
                "{target}にとって、最初の一歩はいつも不安なものです。同じ気持ちを経験したからこそ、寄り添える発信を大切にしています。"
            ]
        case .knowHow:
            return [
                "{business}の発信で反応を上げるコツは、冒頭の一文で「誰への話か」を明確にすること。{target}に向けた言葉を選ぶだけで伝わり方が変わります。",
                "{service}を伝えるときは、専門用語をひとつ減らすところから。分かりやすさは、それ自体が価値になります。"
            ]
        case .experience:
            return [
                "{service}を始めた頃、最初のお問い合わせが来るまで時間がかかりました。その間に続けていた小さな発信が、今につながっています。",
                "{target}と向き合う中で気づいたことを、体験としてそのまま共有します。等身大の話ほど届きやすいと感じています。"
            ]
        case .failure:
            return [
                "以前、宣伝ばかりの発信で反応が落ちた時期がありました。学びは「与える投稿と告知の比率」。今はまず役に立つ話を優先しています。",
                "うまくいかなかったやり方も、振り返れば学びの宝庫です。{business}で遠回りした経験こそ、{target}の役に立つと考えています。"
            ]
        case .promotion:
            return [
                "{target}に向けた{service}のご案内です。詳細はプロフィールのリンクからご覧いただけます。気になる点はお気軽にどうぞ。",
                "{service}では、はじめての方でも迷わないようにサポートしています。今の悩みに合わせてご相談を承っています。"
            ]
        case .question:
            return [
                "{target}のみなさんは、発信の時間をいつ確保していますか？ おすすめの習慣があればぜひ教えてください。",
                "{business}について、いま一番知りたいことは何ですか？ コメントで教えていただけると、今後の発信の参考にします。"
            ]
        case .achievement:
            return [
                "先月は{service}へのお問い合わせが増えました。続けてきた発信の成果を、少しずつ実感しています。",
                "{target}から「分かりやすかった」という声をいただきました。こうした反応が、次の一歩の力になります。"
            ]
        case .other:
            return [
                "今日は少し肩の力を抜いた投稿を。{business}の日々で感じたことを綴っていきます。"
            ]
        }
    }
}
