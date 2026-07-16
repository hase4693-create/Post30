//
//  PostingStreakBadge.swift
//  Post30
//
//  連続投稿日数のピル型バッジ（淡紫背景）。
//  日数は当面サンプル値。将来は投稿履歴からの算出値を渡す想定。
//

import SwiftUI

struct PostingStreakBadge: View {
    let days: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
            Text("\(days)日連続投稿中！")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundStyle(Theme.Color.accentText)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.Color.accentSoft)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(days)日連続で投稿中")
    }
}

#Preview {
    PostingStreakBadge(days: 5)
        .padding()
}
