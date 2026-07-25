//
//  CalendarDayCell.swift
//  Post30
//
//  カレンダーの1日ぶんのセル。日付・今日/選択の識別・投稿状態インジケーターを表示。
//  状態は「色だけ」に依存せず、ドットの形（塗り/枠）＋件数＋accessibilityLabel で区別する。
//

import SwiftUI

struct CalendarDayCell: View {
    let dayNumber: Int
    let isInMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let status: DayPostStatus
    let count: Int
    let accessibilityLabel: String

    var body: some View {
        VStack(spacing: 3) {
            Text("\(dayNumber)")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(numberColor)
                .frame(width: 32, height: 32)
                .background(numberBackground)

            indicator
                .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .opacity(isInMonth ? 1 : 0.35)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var numberColor: Color {
        if isSelected { return .white }
        return isInMonth ? .primary : .secondary
    }

    @ViewBuilder
    private var numberBackground: some View {
        if isSelected {
            Circle().fill(Theme.Color.accent)
        } else if isToday {
            Circle().fill(Theme.Color.accentSoft)
        } else {
            Circle().fill(Color.clear)
        }
    }

    @ViewBuilder
    private var indicator: some View {
        if count > 0 {
            HStack(spacing: 2) {
                statusDot
                if count > 1 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Color.clear
        }
    }

    /// 状態を「形」で区別（枠＝未投稿 / 塗り＝投稿済み / 両方＝混在）。
    @ViewBuilder
    private var statusDot: some View {
        switch status {
        case .none:
            Color.clear.frame(width: 6, height: 6)
        case .unpublishedOnly:
            Circle().stroke(Theme.Color.accent, lineWidth: 1.5).frame(width: 6, height: 6)
        case .publishedOnly:
            Circle().fill(Theme.Color.success).frame(width: 6, height: 6)
        case .mixed:
            HStack(spacing: 1) {
                Circle().stroke(Theme.Color.accent, lineWidth: 1.5).frame(width: 6, height: 6)
                Circle().fill(Theme.Color.success).frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        CalendarDayCell(dayNumber: 1, isInMonth: true, isToday: true, isSelected: false, status: .unpublishedOnly, count: 1, accessibilityLabel: "8月1日")
        CalendarDayCell(dayNumber: 2, isInMonth: true, isToday: false, isSelected: true, status: .publishedOnly, count: 1, accessibilityLabel: "8月2日")
        CalendarDayCell(dayNumber: 3, isInMonth: true, isToday: false, isSelected: false, status: .mixed, count: 3, accessibilityLabel: "8月3日")
        CalendarDayCell(dayNumber: 4, isInMonth: false, isToday: false, isSelected: false, status: .none, count: 0, accessibilityLabel: "7月31日")
    }
    .padding()
}
