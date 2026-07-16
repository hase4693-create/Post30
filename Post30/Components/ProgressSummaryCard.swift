//
//  ProgressSummaryCard.swift
//  Post30
//
//  今月の投稿カード（進捗リング・件数・横型ProgressView）。デザイン案 2 準拠。
//

import SwiftUI

struct ProgressSummaryCard: View {
    let planTitle: String
    let publishedCount: Int
    let totalPostCount: Int
    let unpublishedCount: Int
    let progressRate: Double

    private var percentText: String {
        "\(Int((progressRate * 100).rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            // タイトル行
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今月の投稿")
                        .font(.headline)
                    Text(planTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            // リング＋件数
            HStack(spacing: Theme.Spacing.large) {
                CircularProgressView(progress: progressRate)
                    .frame(width: 84, height: 84)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(publishedCount)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("/ \(totalPostCount) 件")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Text("投稿済み")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // 横型プログレス
            ProgressView(value: progressRate)
                .tint(Theme.Color.accent)

            // 件数の内訳
            HStack {
                countBlock(title: "投稿済み", value: publishedCount, color: Theme.Color.accentText)
                Spacer()
                countBlock(title: "未投稿", value: unpublishedCount, color: .secondary)
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "今月の投稿。\(planTitle)。投稿済み\(publishedCount)件、総数\(totalPostCount)件、未投稿\(unpublishedCount)件、進捗\(percentText)"
        )
    }

    private func countBlock(title: String, value: Int, color: some ShapeStyle) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("\(value)件")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    ProgressSummaryCard(
        planTitle: "2026年8月の投稿計画",
        publishedCount: 3,
        totalPostCount: 30,
        unpublishedCount: 27,
        progressRate: 0.1
    )
    .padding()
}
