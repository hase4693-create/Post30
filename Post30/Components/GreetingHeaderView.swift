//
//  GreetingHeaderView.swift
//  Post30
//
//  時間帯の挨拶（末尾に絵文字）＋現在の日付。右上に丸いアクセントアイコン。
//

import SwiftUI

struct GreetingHeaderView: View {
    let greeting: String
    let emoji: String
    let dateText: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                HStack(spacing: Theme.Spacing.small) {
                    Text(greeting)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(emoji)
                        .font(.title)
                        .accessibilityHidden(true)
                }
                Text(dateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(greeting)。\(dateText)")

            // 右上の丸いアクセントアイコン（Phase 3 は簡易表示）。
            Circle()
                .fill(Theme.Color.accentSoft)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Theme.Color.accentText)
                }
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    GreetingHeaderView(greeting: "おはようございます", emoji: "👋", dateText: "2026年7月15日(水)")
        .padding()
}
