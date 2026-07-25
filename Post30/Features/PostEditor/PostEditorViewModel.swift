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

@MainActor
@Observable
final class PostEditorViewModel {

    // MARK: - 依存

    /// 編集対象（参照型。保存時にこのインスタンスを更新する）。
    private let post: Post
    private let calendar: Calendar
    private let now: () -> Date
    /// 永続化ストア（未注入時はメモリ更新のみ。テストでは nil）。
    private let store: PersistenceStore?
    /// 保存完了時に呼ばれる（呼び出し側で一覧再描画などに使う）。
    private let onSaved: () -> Void

    /// 保存エラー表示用（nil なら非表示）。
    var saveError: String?

    /// 「投稿済みにする」の確認ダイアログ表示状態。
    var showMarkPublishedDialog: Bool = false

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
        store: PersistenceStore? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        onSaved: @escaping () -> Void = {}
    ) {
        self.post = post
        self.store = store
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

    /// 現在の投稿状態（読み取り専用・共通バッジ表示に使用）。
    /// 編集画面では状態を変更しない（投稿済み化は正式な投稿完了処理のみ）。
    var status: PostStatus {
        post.status
    }

    /// 現在の投稿状態の表示名（読み取り専用・PostStatus.displayName と一致）。
    var statusDisplayName: String {
        post.status.displayName
    }

    /// 「投稿済みにする」を実行できる状態か（下書き・予約済みのみ・日付非依存）。
    var canMarkAsPublished: Bool {
        post.canMarkPublished
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

    /// 画面上の編集内容を Post へ反映する（status/publishedAt には触れない・保存はしない）。
    private func applyEdits() {
        let comps = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        post.content = content
        post.category = category
        post.platform = platform
        post.scheduledDate = calendar.startOfDay(for: scheduledDate)
        post.scheduledTime = DateComponents(hour: comps.hour, minute: comps.minute)
        post.memo = normalizedMemo.isEmpty ? nil : normalizedMemo
        post.updatedAt = now()
    }

    /// 編集内容を Post へ反映し永続化する。status/publishedAt は変更しない。
    /// 成功したら true。保存不可や保存失敗（saveError を設定）なら false を返し、
    /// 呼び出し側は画面を閉じない。
    @discardableResult
    func save() -> Bool {
        guard canSave else { return false }
        applyEdits()

        do {
            try store?.save()
        } catch {
            saveError = "データを保存できませんでした。もう一度お試しください。"
            return false
        }

        onSaved()
        return true
    }

    // MARK: - 投稿済みにする（明示操作）

    /// 「投稿済みにする」ボタン押下：確認ダイアログを出す。
    func requestMarkAsPublished() {
        guard canMarkAsPublished else { return }
        showMarkPublishedDialog = true
    }

    /// 確認ダイアログの確定：編集内容を含めて1回の保存で投稿済みにする。
    /// 保存失敗時は状態変更を巻き戻して saveError を立て、false を返す（画面は閉じない）。
    @discardableResult
    func confirmMarkAsPublished() -> Bool {
        guard canMarkAsPublished, canSave else { return false }

        applyEdits()
        // 巻き戻し用に投稿完了前の状態を保持。
        let previousStatus = post.status
        let previousPublishedAt = post.publishedAt
        post.markPublished(at: now())

        do {
            try store?.save()
        } catch {
            // 投稿済み表示を確定させない：状態遷移を元に戻す。
            post.status = previousStatus
            post.publishedAt = previousPublishedAt
            saveError = "データを保存できませんでした。もう一度お試しください。"
            return false
        }

        onSaved()
        return true
    }
}
