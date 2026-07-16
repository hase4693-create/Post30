//
//  NextPostCard.swift
//  Post30
//
//  次回予定の投稿カード。カード全体をタップ可能にし、将来の編集画面遷移に備える。
//  showBody で本文プレビューの有無を切り替える（今日あり=簡潔／今日なし=本文あり）。
//

import SwiftUI

struct NextPostCard: View {
    let post: Post
    /// 予定日テキスト（例: 8月4日(火)）。ViewModel から整形済みで渡す。
    let dateText: String
    var showBody: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                HStack(spacing: Theme.Spacing.small) {
                    CategoryTag(category: post.category)

                    if let time = post.scheduledTimeText {
                        Label("\(dateText) \(time)", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(dateText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: Theme.Spacing.small)

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(post.platform.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if showBody {
                    Text(post.content)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "次回予定 \(dateText)。カテゴリー \(post.category.displayName)。\(post.platform.displayName)"
        )
        .accessibilityHint("タップして詳細を開きます")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NextPostCard(
        post: Post(
            scheduledDate: Date(),
            scheduledTime: DateComponents(hour: 8, minute: 0),
            platform: .threads,
            category: .failure,
            content: "【4日目・失敗談】以前、宣伝ばかりして反応が激減しました。学びは「与える投稿と告知の比率」でした。",
            status: .scheduled
        ),
        dateText: "8月4日(火)",
        showBody: true,
        onTap: {}
    )
    .padding()
}
