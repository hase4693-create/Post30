//
//  CategoryTag.swift
//  Post30
//
//  投稿カテゴリーのタグ（角丸8・淡紫背景・紫文字）。
//

import SwiftUI

struct CategoryTag: View {
    let category: PostCategory

    var body: some View {
        Text(category.displayName)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Theme.Color.accentText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.Color.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.tagCornerRadius))
            .accessibilityLabel("カテゴリー \(category.displayName)")
    }
}

#Preview {
    HStack {
        CategoryTag(category: .empathy)
        CategoryTag(category: .failure)
    }
    .padding()
}
