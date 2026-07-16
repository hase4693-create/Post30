//
//  Date+Extensions.swift
//  Post30
//
//  日時処理のヘルパー。タイムゾーン依存のバグを避けるため
//  比較は可能な限り Calendar を用いる。
//

import Foundation

extension Date {
    /// 指定カレンダーで同じ「日」かどうかを判定する。
    func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }

    /// 指定日数を加えた日付を返す。加算できない場合は self を返す。
    func adding(days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// その日の 0:00（カレンダー基準）を返す。
    func startOfDay(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
}
