//
//  CalendarDateHelper.swift
//  Post30
//
//  カレンダーの日付計算（月グリッド生成・同一日判定・月移動・年月タイトル）。
//  View から切り離してテスト可能にする純ロジック。日曜始まり・端末タイムゾーン基準。
//

import Foundation

/// カレンダー1マスぶんの日付。
struct CalendarDay: Identifiable, Hashable {
    /// その日の 0:00（同一日判定に使う）。
    let date: Date
    /// 表示対象月の日かどうか（前後月の補助日は false）。
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

enum CalendarDateHelper {

    /// 指定日を含む月の1日 0:00 を返す。
    static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    /// 月の日数。
    static func numberOfDays(in month: Date, calendar: Calendar) -> Int {
        calendar.range(of: .day, in: .month, for: startOfMonth(month, calendar: calendar))?.count ?? 30
    }

    /// 指定月の日曜始まりグリッドを生成する。
    /// 月初の曜日に応じて前月の補助日を、末尾は週が揃うよう次月の補助日を配置する。
    /// セル数は 35 または 42（必要な週数×7）になる。
    static func makeMonthGrid(for month: Date, calendar: Calendar) -> [CalendarDay] {
        let firstOfMonth = startOfMonth(month, calendar: calendar)
        let daysInMonth = numberOfDays(in: firstOfMonth, calendar: calendar)
        let weekday = calendar.component(.weekday, from: firstOfMonth) // 1(日)〜7(土)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        var days: [CalendarDay] = []

        // 前月の補助日
        if leading > 0 {
            for offset in stride(from: leading, through: 1, by: -1) {
                if let d = calendar.date(byAdding: .day, value: -offset, to: firstOfMonth) {
                    days.append(CalendarDay(date: calendar.startOfDay(for: d), isInDisplayedMonth: false))
                }
            }
        }

        // 当月
        for day in 0..<daysInMonth {
            if let d = calendar.date(byAdding: .day, value: day, to: firstOfMonth) {
                days.append(CalendarDay(date: calendar.startOfDay(for: d), isInDisplayedMonth: true))
            }
        }

        // 週を揃えるための次月の補助日
        let remainder = days.count % 7
        if remainder != 0, let lastDate = days.last?.date {
            let trailing = 7 - remainder
            for offset in 1...trailing {
                if let d = calendar.date(byAdding: .day, value: offset, to: lastDate) {
                    days.append(CalendarDay(date: calendar.startOfDay(for: d), isInDisplayedMonth: false))
                }
            }
        }

        return days
    }

    /// 2つの日付が同一日か（時刻差は無視）。
    static func isSameDay(_ lhs: Date, _ rhs: Date, calendar: Calendar) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    /// 指定月に月数を加えた月の1日を返す（年またぎ・うるう年に対応）。
    static func month(byAddingMonths value: Int, to month: Date, calendar: Calendar) -> Date {
        let first = startOfMonth(month, calendar: calendar)
        return calendar.date(byAdding: .month, value: value, to: first) ?? first
    }

    /// 年月タイトル（例: 2026年8月）。
    static func monthTitle(for month: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: month)
    }
}
