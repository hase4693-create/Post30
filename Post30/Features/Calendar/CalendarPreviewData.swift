//
//  CalendarPreviewData.swift
//  Post30
//
//  カレンダー Preview 専用データ（DEBUG 限定・本番 SampleData とは分離）。
//

#if DEBUG
import Foundation

enum CalendarPreviewData {

    private static let calendar = Calendar.current

    private static func day(offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    private static func post(offset: Int, status: PostStatus, hour: Int = 8) -> Post {
        Post(
            scheduledDate: day(offset: offset),
            scheduledTime: DateComponents(hour: hour, minute: 0),
            platform: .threads, category: .other,
            content: "プレビュー投稿（\(offset)日目）です。カレンダー確認用の本文です。",
            status: status
        )
    }

    private static func planWithPosts() -> MonthPlan {
        let plan = MonthPlan(
            title: "プレビュー計画", year: 2026, month: 8,
            startDate: day(offset: 0), endDate: day(offset: 29), status: .active
        )
        plan.addPosts([
            post(offset: 0, status: .scheduled, hour: 8),   // 今日：複数
            post(offset: 0, status: .scheduled, hour: 19),
            post(offset: 2, status: .published),            // 投稿済みのみ
            post(offset: 5, status: .scheduled),            // 混在
            post(offset: 5, status: .published, hour: 20),
            post(offset: 9, status: .draft)                 // 未投稿のみ
        ])
        return plan
    }

    // 複数の投稿日がある月（今日が選択され複数投稿）
    static func monthWithPosts() -> CalendarViewModel {
        CalendarViewModel(plan: planWithPosts(), calendar: calendar)
    }

    // 投稿がない月
    static func emptyMonth() -> CalendarViewModel {
        let plan = MonthPlan(
            title: "空の計画", year: 2026, month: 9,
            startDate: day(offset: 0), endDate: day(offset: 29), status: .draft
        )
        return CalendarViewModel(plan: plan, calendar: calendar)
    }

    // 選択日に投稿がない状態
    static func selectedWithoutPosts() -> CalendarViewModel {
        let vm = CalendarViewModel(plan: planWithPosts(), calendar: calendar)
        vm.select(day(offset: 15)) // 投稿のない日
        return vm
    }

    // 選択日に混在（未投稿＋投稿済み）
    static func selectedMixed() -> CalendarViewModel {
        let vm = CalendarViewModel(plan: planWithPosts(), calendar: calendar)
        vm.select(day(offset: 5)) // 混在の日
        return vm
    }
}
#endif
