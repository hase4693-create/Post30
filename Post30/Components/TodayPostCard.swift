//
//  TodayPostCard.swift
//  Post30
//
//  今日の投稿カード（カテゴリー・SNS・予定時刻・本文・3アクション）。デザイン案 2 準拠。
//

import SwiftUI

struct TodayPostCard: View {
    let post: Post
    /// 予定日テキスト（例: 7月15日(水)）。
    let dateText: String
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onMarkPublished: () -> Void

    private var isPublished: Bool { post.status == .published }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            // 上段（カテゴリー・SNS・予定日時）
            HStack(spacing: Theme.Spacing.small) {
                CategoryTag(category: post.category)
                Spacer()
                if let time = post.scheduledTimeText {
                    Label("\(dateText) \(time)", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(post.platform.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 本文（Dynamic Type 拡大時に固定高さで切れない）
            Text(post.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // アクション（横並び3つ）
            HStack(spacing: Theme.Spacing.medium) {
                outlineButton(title: "コピー", systemImage: "doc.on.doc", action: onCopy)
                    .accessibilityHint("投稿本文をコピーします")
                outlineButton(title: "編集", systemImage: "pencil", action: onEdit)
                    .accessibilityHint("編集画面を開きます")
                if isPublished {
                    publishedLabel
                } else {
                    filledButton(title: "投稿済みにする", systemImage: "checkmark.circle", action: onMarkPublished)
                        .accessibilityHint("この投稿を投稿済みにします")
                }
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: - ボタン部品

    private func outlineButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.Layout.minTapTarget)
            .padding(.vertical, Theme.Spacing.small)
            .foregroundStyle(Theme.Color.accentText)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.actionButtonCornerRadius)
                    .stroke(Theme.Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
    }

    private func filledButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.Layout.minTapTarget)
            .padding(.vertical, Theme.Spacing.small)
            .foregroundStyle(.white)
            .background(Theme.Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.actionButtonCornerRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
    }

    private var publishedLabel: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
            Text("投稿済み")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: Theme.Layout.minTapTarget)
        .padding(.vertical, Theme.Spacing.small)
        .foregroundStyle(.secondary)
        .background(Theme.Color.accentSoft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.actionButtonCornerRadius))
        .accessibilityLabel("投稿済み")
    }
}

#Preview {
    VStack {
        TodayPostCard(
            post: Post(
                scheduledDate: Date(),
                scheduledTime: DateComponents(hour: 8, minute: 0),
                platform: .threads,
                category: .empathy,
                content: "朝の30分を自分のために使うと、1日が変わります。",
                status: .scheduled
            ),
            dateText: "7月15日(水)",
            onCopy: {}, onEdit: {}, onMarkPublished: {}
        )
    }
    .padding()
}
