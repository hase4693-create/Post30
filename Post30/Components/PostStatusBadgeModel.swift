//
//  PostStatusBadgeModel.swift
//  Post30
//
//  投稿ステータスバッジの表示モデル（Presentation-safe・SwiftUI 非依存）。
//  表示文言は PostStatus.displayName（唯一の基準）を使用し、
//  日付・現在時刻には一切依存しない。色は UI 層（PostStatusBadge）で解決する。
//

import Foundation

struct PostStatusBadgeModel: Equatable {
    /// 表示文言（PostStatus.displayName と一致）。
    let title: String
    /// SF Symbols 名。
    let systemImageName: String

    init(status: PostStatus) {
        self.title = status.displayName
        switch status {
        case .draft:
            self.systemImageName = "doc.text"
        case .scheduled:
            self.systemImageName = "clock"
        case .published:
            self.systemImageName = "checkmark.circle.fill"
        case .skipped:
            self.systemImageName = "minus.circle"
        }
    }
}
