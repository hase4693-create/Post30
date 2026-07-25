//
//  PostStatusBadge.swift
//  Post30
//
//  投稿ステータスを示す共通バッジ（テキスト＋アイコン＋淡色背景のカプセル）。
//  一覧カード等で再利用する。判定は保存済みの PostStatus のみで、日付には依存しない。
//  色だけに頼らず必ずテキストを併記し、VoiceOver では状態名を読み上げる。
//

import SwiftUI

struct PostStatusBadge: View {
    let status: PostStatus

    private var model: PostStatusBadgeModel { PostStatusBadgeModel(status: status) }

    var body: some View {
        Label {
            Text(model.title)
        } icon: {
            Image(systemName: model.systemImageName)
        }
        .labelStyle(.titleAndIcon)
        .font(.caption2.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor, in: Capsule())
        // カード全体のタップを妨げないよう、独自の操作は付けない。
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("投稿状態")
        .accessibilityValue(model.title)
    }

    // MARK: - 色（UI 層でのみ解決）

    private var foregroundColor: Color {
        switch status {
        case .draft: return .secondary
        case .scheduled: return Theme.Color.info
        case .published: return Theme.Color.success
        case .skipped: return .secondary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .draft: return Color(.secondarySystemFill)
        case .scheduled: return Theme.Color.info.opacity(0.15)
        case .published: return Theme.Color.success.opacity(0.15)
        case .skipped: return Color(.secondarySystemFill)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        PostStatusBadge(status: .draft)
        PostStatusBadge(status: .scheduled)
        PostStatusBadge(status: .published)
        PostStatusBadge(status: .skipped)
    }
    .padding()
}
