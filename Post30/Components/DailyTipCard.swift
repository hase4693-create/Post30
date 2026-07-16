//
//  DailyTipCard.swift
//  Post30
//
//  「今日のヒント」カード。Phase 3 では固定サンプル文。将来差し替え可能。
//

import SwiftUI

struct DailyTipCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            Image(systemName: "lightbulb")
                .foregroundStyle(Theme.Color.accentText)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("今日のヒント")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日のヒント。\(text)")
    }
}

#Preview {
    DailyTipCard(text: "共感を生む投稿は、あなたの体験から生まれます。小さな気づきも立派なコンテンツです。")
        .padding()
}
