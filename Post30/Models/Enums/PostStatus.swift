//
//  PostStatus.swift
//  Post30
//
//  投稿1件のステータスを表す列挙型。
//

import Foundation

/// 投稿の状態。
enum PostStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    /// 下書き
    case draft
    /// 投稿予定
    case scheduled
    /// 投稿済み
    case published
    /// 見送り
    case skipped

    var id: String { rawValue }

    /// 日本語の表示名。
    var displayName: String {
        switch self {
        case .draft: return "下書き"
        case .scheduled: return "予定"
        case .published: return "投稿済み"
        case .skipped: return "見送り"
        }
    }
}
