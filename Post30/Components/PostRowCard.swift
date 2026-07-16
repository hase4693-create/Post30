//
//  PostRowCard.swift
//  Post30
//
//  投稿一覧のセル（カードUI・角丸16）。カテゴリー・SNS・日時・状態・本文を表示。
//

import SwiftUI

struct PostRowCard: View {
    let post: Post
    /// 予定日テキスト（例: 7月15日(水)）。
    let dateText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                // 上段: カテゴリー・SNS・状態アイコン
                HStack(spacing: Theme.Spacing.small) {
                    CategoryTag(category: post.category)
                    Text(post.platform.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    statusIcon
                }

                // 日時
                if let time = post.scheduledTimeText {
                    Label("\(dateText) \(time)", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Label(dateText, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // 本文（最大3行）
                Text(post.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("タップして編集画面を開きます")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch post.status {
        case .published:
            Label(post.status.displayName, systemImage: "checkmark.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(Theme.Color.success)
        case .skipped:
            Label(post.status.displayName, systemImage: "minus.circle")
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
        case .draft, .scheduled:
            Label(post.status.displayName, systemImage: "clock")
                .labelStyle(.iconOnly)
                .foregroundStyle(Theme.Color.accentText)
        }
    }

    private var accessibilityText: String {
        let time = post.scheduledTimeText.map { " \($0)" } ?? ""
        return "\(post.category.displayName)、\(post.platform.displayName)、\(dateText)\(time)、\(post.status.displayName)。\(post.content)"
    }
}

#Preview {
    VStack(spacing: 16) {
        PostRowCard(
            post: Post(
                scheduledDate: Date(),
                scheduledTime: DateComponents(hour: 8, minute: 0),
                platform: .threads,
                category: .empathy,
                content: "朝の30分を自分のために使うと、1日が変わります。今日はどんな時間を大切にしますか？",
                status: .scheduled
            ),
            dateText: "7月15日(水)",
            onTap: {}
        )
        PostRowCard(
            post: Post(
                scheduledDate: Date(),
                scheduledTime: DateComponents(hour: 19, minute: 0),
                platform: .threads,
                category: .knowHow,
                content: "投稿を続けるコツは完璧を目指さないこと。",
                status: .published
            ),
            dateText: "7月14日(火)",
            onTap: {}
        )
    }
    .padding()
}
