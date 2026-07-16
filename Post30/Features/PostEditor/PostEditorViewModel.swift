//
//  PostEditorViewModel.swift
//  Post30
//
//  投稿編集画面のロジック（MVVM）。
//  編集データの保持・入力チェック・保存可否・保存処理・未保存変更検知を担う。
//  保存はメモリ上の Post（参照型）を直接更新するため、同じ Post を参照する
//  ホーム・投稿一覧へ即時反映される（SwiftData はまだ使用しない）。
//

import Foundation
import Observation

@Observable
final class PostEditorViewModel {

    // MARK: - 依存

    /// 編集対象（参照型。保存時にこのインスタンスを更新する）。
    private let post: Post
    private let calendar: Calendar
    private let now: () -> Date
    /// 保存完了時に呼ばれる（呼び出し側で一覧再描画などに使う）。
    private let onSaved: () -> Void

    // MARK: - 編集中の値

    var category: PostCategory
    var platform: SocialPlatform
    var scheduledDate: Date
    /// 時刻は DatePicker 用に Date で保持し、保存時に時・分へ変換する。
    var scheduledTime: Date
    var content: String
    var memo: String

    // 変更検知の基準（初期化時の時刻）。
    private let originalHour: Int
    private let originalMinute: Int

    init(
        post: Post,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        onSaved: @escaping () -> Void = {}
    ) {
        self.post = post
        self.calendar = calendar
        self.now = now
        self.onSaved = onSaved

        self.category = post.category
        self.platform = post.platform
        self.scheduledDate = post.scheduledDate
        self.content = post.content
        self.memo = post.memo ?? ""

        let baseComponents = post.scheduledTime ?? DateComponents(hour: 8, minute: 0)
        let hour = baseComponents.hour ?? 8
        let minute = baseComponents.minute ?? 0
        self.originalHour = hour
        self.originalMinute = minute
        self.scheduledTime = calendar.date(
            bySettingHour: hour, minute: minute, second: 0, of: post.scheduledDate
        ) ?? post.scheduledDate
    }

    // MARK: - 入力チェック

    /// 本文が空（空白のみ含む）でないか。
    var isContentValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 保存可否。本文が有効なときのみ保存できる。
    var canSave: Bool {
        isContentValid
    }

    /// メモの正規化値（前後の空白を除去。空なら空文字）。
    private var normalizedMemo: String {
        memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 未保存変更検知

    var hasUnsavedChanges: Bool {
        if content != post.content { return true }
        if category != post.category { return true }
        if platform != post.platform { return true }
        if !calendar.isDate(scheduledDate, inSameDayAs: post.scheduledDate) { return true }
        let comps = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        if comps.hour != originalHour || comps.minute != originalMinute { return true }
        if normalizedMemo != (post.memo ?? "") { return true }
        return false
    }

    // MARK: - 保存

    /// 編集内容を Post へ反映する。保存不可なら何もしない。
    func save() {
        guard canSave else { return }
        let comps = calendar.dateComponents([.hour, .minute], from: scheduledTime)

        post.content = content
        post.category = category
        post.platform = platform
        post.scheduledDate = calendar.startOfDay(for: scheduledDate)
        post.scheduledTime = DateComponents(hour: comps.hour, minute: comps.minute)
        post.memo = normalizedMemo.isEmpty ? nil : normalizedMemo
        post.updatedAt = now()

        onSaved()
    }
}
