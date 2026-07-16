//
//  SocialPlatform.swift
//  Post30
//
//  投稿先SNSを表す列挙型。
//

import Foundation

/// 投稿先のSNSプラットフォーム。
///
/// - Note: 特定SNSのブランドカラーはここに固定しない。
///   色はUI側（Theme等）で扱い、モデルは識別のみを担う。
enum SocialPlatform: String, CaseIterable, Codable, Identifiable, Sendable {
    case threads
    case instagram
    case x
    case other

    var id: String { rawValue }

    /// UIやデータ保存で使う安定した識別子。
    /// rawValue を単一の真実として扱い、表示名の変更に影響されないようにする。
    var identifier: String { rawValue }

    /// 日本語（またはブランド名）の表示名。
    var displayName: String {
        switch self {
        case .threads: return "Threads"
        case .instagram: return "Instagram"
        case .x: return "X"
        case .other: return "その他"
        }
    }

    /// UIで用いるSF Symbols名（暫定。UIフェーズで調整可）。
    var symbolName: String {
        switch self {
        case .threads: return "at"
        case .instagram: return "camera"
        case .x: return "xmark.square"
        case .other: return "square.grid.2x2"
        }
    }
}
