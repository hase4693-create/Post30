//
//  CalendarMonthHeader.swift
//  Post30
//
//  カレンダー上部の年月表示と前月/次月ボタン。
//

import SwiftUI

struct CalendarMonthHeader: View {
    let title: String
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .frame(minWidth: Theme.Layout.minTapTarget, minHeight: Theme.Layout.minTapTarget)
            }
            .foregroundStyle(Theme.Color.accentText)
            .accessibilityLabel("前の月")

            Spacer()

            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .frame(minWidth: Theme.Layout.minTapTarget, minHeight: Theme.Layout.minTapTarget)
            }
            .foregroundStyle(Theme.Color.accentText)
            .accessibilityLabel("次の月")
        }
    }
}

#Preview {
    CalendarMonthHeader(title: "2026年8月", onPrevious: {}, onNext: {})
        .padding()
}
