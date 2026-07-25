//
//  DailyPostListView.swift
//  Post30
//
//  選択日の投稿一覧セクション。既存の PostRowCard を再利用する。
//  投稿タップで既存の投稿編集画面へ遷移するためのコールバックを受け取る。
//

import SwiftUI

struct DailyPostListView: View {
    let title: String
    let posts: [Post]
    /// 各投稿の日時テキスト（ViewModel で整形して渡す）。
    let dateText: (Post) -> String
    let onSelect: (Post) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.cardSpacing) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if posts.isEmpty {
                emptyState
            } else {
                ForEach(posts) { post in
                    PostRowCard(
                        post: post,
                        dateText: dateText(post),
                        onTap: { onSelect(post) }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.small) {
            Image(systemName: "calendar.day.timeline.left")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("この日の投稿はありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.large)
    }
}

#if DEBUG
#Preview {
    DailyPostListView(
        title: "8月15日(土)の投稿",
        posts: [],
        dateText: { _ in "8月15日(土) 08:00" },
        onSelect: { _ in }
    )
    .padding()
}
#endif
