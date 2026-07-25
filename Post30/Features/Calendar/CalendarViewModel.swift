//
//  CalendarViewModel.swift
//  Post30
//
//  カレンダー画面のロジック（MVVM）。表示月・選択日・月移動・日別抽出・状態判定を担う。
//  永続化は行わず、既存 MonthPlan（SwiftData）の posts を正として読み取るのみ。
//  投稿日の変更・保存は既存の投稿編集画面（PostEditorView）を再利用する。
//

import Foundation
import Observation

/// 日付セルの投稿状態（色だけに依存させないための分類）。
enum DayPostStatus: Equatable {
    case none            // 投稿なし
    case unpublishedOnly // 未投稿（draft/scheduled）のみ
    case publishedOnly   // 投稿済み（published）のみ
    case mixed           // 未投稿と投稿済みが混在

    /// VoiceOver 等で使う日本語表現。
    var accessibilityText: String {
        switch self {
        case .none: return "投稿予定なし"
        case .unpublishedOnly: return "未投稿あり"
        case .publishedOnly: return "投稿済みあり"
        case .mixed: return "未投稿と投稿済みが混在"
        }
    }
}

@Observable
final class CalendarViewModel {

    // MARK: - 依存
    private let plan: MonthPlan?
    private let calendar: Calendar
    private let locale: Locale
    private let now: () -> Date

    // MARK: - 状態
    private(set) var displayedMonth: Date
    private(set) var selectedDate: Date

    init(
        plan: MonthPlan?,
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "ja_JP"),
        now: @escaping () -> Date = { Date() }
    ) {
        // 日曜始まり・日本語ロケールを基本にする。
        var cal = calendar
        cal.firstWeekday = 1
        cal.locale = locale
        self.plan = plan
        self.calendar = cal
        self.locale = locale
        self.now = now
        self.displayedMonth = CalendarDateHelper.startOfMonth(now(), calendar: cal)
        self.selectedDate = cal.startOfDay(for: now())
    }

    // MARK: - 表示データ

    /// 表示月の日付グリッド（35 or 42 セル）。
    var days: [CalendarDay] {
        CalendarDateHelper.makeMonthGrid(for: displayedMonth, calendar: calendar)
    }

    /// 年月タイトル（例: 2026年8月）。
    var monthTitle: String {
        CalendarDateHelper.monthTitle(for: displayedMonth, calendar: calendar, locale: locale)
    }

    /// 曜日見出し（日曜始まり）。
    var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }

    /// 選択日の見出し（例: 8月15日(土)）。
    var selectedDateTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MdEEE")
        return formatter.string(from: selectedDate)
    }

    // MARK: - 判定

    func isToday(_ date: Date) -> Bool {
        CalendarDateHelper.isSameDay(date, now(), calendar: calendar)
    }

    func isSelected(_ date: Date) -> Bool {
        CalendarDateHelper.isSameDay(date, selectedDate, calendar: calendar)
    }

    func dayNumber(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    // MARK: - 投稿の抽出（複製しない・読み取りのみ）

    /// 指定日の投稿（予定日時→時刻順）。既存 posts を絞り込むだけで複製しない。
    func posts(on date: Date) -> [Post] {
        (plan?.posts ?? [])
            .filter { CalendarDateHelper.isSameDay($0.scheduledDate, date, calendar: calendar) }
            .sorted { lhs, rhs in
                if !CalendarDateHelper.isSameDay(lhs.scheduledDate, rhs.scheduledDate, calendar: calendar) {
                    return lhs.scheduledDate < rhs.scheduledDate
                }
                return (lhs.scheduledHour ?? 0, lhs.scheduledMinute ?? 0)
                     < (rhs.scheduledHour ?? 0, rhs.scheduledMinute ?? 0)
            }
    }

    /// 指定日の投稿件数。
    func postCount(on date: Date) -> Int {
        posts(on: date).count
    }

    /// 指定日の投稿状態。
    func dayStatus(for date: Date) -> DayPostStatus {
        let dayPosts = posts(on: date)
        guard !dayPosts.isEmpty else { return .none }
        let hasPublished = dayPosts.contains { $0.status == .published }
        let hasUnpublished = dayPosts.contains { $0.status == .draft || $0.status == .scheduled }
        switch (hasUnpublished, hasPublished) {
        case (true, true): return .mixed
        case (true, false): return .unpublishedOnly
        case (false, true): return .publishedOnly
        case (false, false): return .none // 見送りのみ等
        }
    }

    /// 選択日の投稿。
    var selectedDatePosts: [Post] {
        posts(on: selectedDate)
    }

    /// セルのアクセシビリティ用ラベル（色に依存しない説明）。
    func accessibilityLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("Md")
        var label = formatter.string(from: date)
        if isToday(date) { label += "、今日" }
        let count = postCount(on: date)
        if count > 0 {
            label += "、投稿\(count)件、\(dayStatus(for: date).accessibilityText)"
        } else {
            label += "、投稿予定なし"
        }
        if isSelected(date) { label += "、選択中" }
        return label
    }

    /// 一覧表示用の予定日時テキスト（例: 8月15日(土) 08:00）。
    func dateText(for post: Post) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MdEEE")
        let dateStr = formatter.string(from: post.scheduledDate)
        if let time = post.scheduledTimeText {
            return "\(dateStr) \(time)"
        }
        return dateStr
    }

    // MARK: - 月移動・選択

    func goToPreviousMonth() {
        displayedMonth = CalendarDateHelper.month(byAddingMonths: -1, to: displayedMonth, calendar: calendar)
        adjustSelectionForDisplayedMonth()
    }

    func goToNextMonth() {
        displayedMonth = CalendarDateHelper.month(byAddingMonths: 1, to: displayedMonth, calendar: calendar)
        adjustSelectionForDisplayedMonth()
    }

    /// 日付タップ。別月の補助日をタップした場合は表示月も移動する。
    func select(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = CalendarDateHelper.startOfMonth(date, calendar: calendar)
        }
    }

    /// 月移動時の選択日ルール：
    /// 移動先の月に今日が含まれれば今日、含まれなければ移動先月の1日。
    private func adjustSelectionForDisplayedMonth() {
        let today = calendar.startOfDay(for: now())
        if calendar.isDate(today, equalTo: displayedMonth, toGranularity: .month) {
            selectedDate = today
        } else {
            selectedDate = CalendarDateHelper.startOfMonth(displayedMonth, calendar: calendar)
        }
    }

    // MARK: - 今日へ戻る

    /// 表示月を今日を含む月にし、選択日を今日にする。
    /// 日付は now() から1回だけ取得し、端末のロケール/タイムゾーンに従う。
    func selectToday() {
        let today = now()
        displayedMonth = CalendarDateHelper.startOfMonth(today, calendar: calendar)
        selectedDate = calendar.startOfDay(for: today)
    }

    /// 現在は「今日を含む月」を表示し、かつ今日を選択中か（ボタンの無効化に使用）。
    var isViewingToday: Bool {
        let today = now()
        let sameMonth = calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month)
        return sameMonth && CalendarDateHelper.isSameDay(selectedDate, today, calendar: calendar)
    }
}
