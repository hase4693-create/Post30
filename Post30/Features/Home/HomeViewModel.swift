//
//  HomeViewModel.swift
//  Post30
//
//  ホーム画面のロジックを担う ViewModel（MVVM）。
//  View には業務ロジックを持たせず、状態と表示値・アクションをここへ集約する。
//  現在日時は注入（now クロージャ）してテスト可能にする。
//

import Foundation
import Observation

@Observable
final class HomeViewModel {

    /// ホームからの遷移経路（プレースホルダを含む）。
    enum Route: Hashable {
        case edit(Post)
        case generate
    }

    // MARK: - 依存（注入）

    private let clipboardService: ClipboardService
    private let calendar: Calendar
    /// 現在日時の供給源（テストで固定するため注入）。
    private let now: () -> Date

    /// 対象の月次計画（未設定なら nil）。
    private let plan: MonthPlan?

    // MARK: - 公開状態

    private(set) var state: HomeViewState = .loading

    /// 「コピーしました」通知の表示状態（UI状態）。
    var showCopyToast: Bool = false

    /// ナビゲーション経路（編集・生成プレースホルダへの遷移を管理）。
    var path: [Route] = []

    // MARK: - 初期化

    init(
        plan: MonthPlan?,
        clipboardService: ClipboardService,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.plan = plan
        self.clipboardService = clipboardService
        self.calendar = calendar
        self.now = now
        reload()
    }

    // MARK: - 状態構築

    /// plan と現在日時から state を再構築する。
    func reload() {
        guard let plan, plan.totalPostCount > 0 else {
            state = .empty
            return
        }
        let today = plan.posts(on: now(), calendar: calendar).first
        // 次回予定は常に算出する。今日の投稿がある場合は「翌日以降」の次回を返す。
        let next: Post?
        if today == nil {
            next = plan.nextScheduledPost(after: now(), calendar: calendar)
        } else {
            let tomorrow = calendar.startOfDay(for: now()).adding(days: 1, calendar: calendar)
            next = plan.nextScheduledPost(after: tomorrow, calendar: calendar)
        }
        state = .content(HomeContent(plan: plan, todayPost: today, nextPost: next))
    }

    // MARK: - 表示値

    /// 時間帯に応じた挨拶。
    var greeting: String {
        switch currentHour {
        case 5..<11:
            return "おはようございます"
        case 11..<18:
            return "こんにちは"
        default:
            return "こんばんは"
        }
    }

    /// 挨拶の末尾に添える時間帯の絵文字。
    var greetingEmoji: String {
        switch currentHour {
        case 5..<11:
            return "👋"
        case 11..<18:
            return "☀️"
        default:
            return "🌙"
        }
    }

    private var currentHour: Int {
        calendar.component(.hour, from: now())
    }

    /// 連続投稿日数（当面はサンプル値。将来は投稿履歴から算出して差し替える）。
    var postingStreakDays: Int { 5 }

    /// 今日のヒント（Phase 3 は固定サンプル文。将来差し替え）。
    var dailyTip: String {
        "共感を生む投稿は、あなたの体験から生まれます。小さな気づきも立派なコンテンツです。"
    }

    /// 現在の日付テキスト（例: 2026年8月1日(金)）。
    var dateText: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.setLocalizedDateFormatFromTemplate("yMMMdEEE")
        return formatter.string(from: now())
    }

    var planTitle: String? { plan?.title }
    var publishedCount: Int { plan?.publishedCount ?? 0 }
    var unpublishedCount: Int { plan?.unpublishedCount ?? 0 }
    var totalPostCount: Int { plan?.totalPostCount ?? 0 }
    var publishedProgressRate: Double { plan?.publishedProgressRate ?? 0 }

    /// 投稿の予定日テキスト（例: 8月4日(火)）。
    func scheduledDateText(for post: Post) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
        return formatter.string(from: post.scheduledDate)
    }

    // MARK: - アクション

    /// 投稿本文をクリップボードへコピーし、通知状態を立てる。
    func copy(_ post: Post) {
        clipboardService.copy(post.content)
        showCopyToast = true
    }

    /// 投稿を「投稿済み」にする。既に published の場合は二重実行しない。
    func markAsPublished(_ post: Post) {
        guard post.status != .published else { return }
        let timestamp = now()
        post.status = .published
        post.publishedAt = timestamp
        post.updatedAt = timestamp
        reload() // 進捗件数・率を即時再計算
    }

    /// 編集プレースホルダへの遷移をトリガする（対象 Post を渡す）。
    func requestEdit(_ post: Post) {
        path.append(.edit(post))
    }

    /// 30日分生成プレースホルダへの遷移をトリガする。
    func requestGenerate() {
        path.append(.generate)
    }
}
