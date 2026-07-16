//
//  EmptyStateView.swift
//  Post30
//
//  計画がない／投稿0件のときの空状態表示。
//

import SwiftUI

struct EmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.accent)
                .accessibilityHidden(true)

            Text("今月の投稿計画がまだありません")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("AIで30日分の投稿を作成して、\nSNS運用を始めましょう。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            PrimaryButton(
                title: "AIで30日分の投稿を作成",
                leadingSystemImage: "sparkles",
                trailingSystemImage: "chevron.right",
                fill: .gradient,
                action: onCreate
            )
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.large)
        .cardSurface()
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    EmptyStateView(onCreate: {})
        .padding()
}
