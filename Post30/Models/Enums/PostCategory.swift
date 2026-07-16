//
//  PostCategory.swift
//  Post30
//
//  投稿の内容カテゴリを表す列挙型。
//

import Foundation

/// 投稿のカテゴリ（投稿ネタの型）。
enum PostCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    /// 共感
    case empathy
    /// ノウハウ
    case knowHow
    /// 体験談
    case experience
    /// 失敗談
    case failure
    /// 宣伝
    case promotion
    /// 質問
    case question
    /// 実績
    case achievement
    /// その他
    case other

    var id: String { rawValue }

    /// 日本語の表示名。
    var displayName: String {
        switch self {
        case .empathy: return "共感"
        case .knowHow: return "ノウハウ"
        case .experience: return "体験談"
        case .failure: return "失敗談"
        case .promotion: return "宣伝"
        case .question: return "質問"
        case .achievement: return "実績"
        case .other: return "その他"
        }
    }

    /// 短い説明文。
    var summary: String {
        switch self {
        case .empathy: return "読み手の気持ちに寄り添う投稿"
        case .knowHow: return "役立つ知識やコツを伝える投稿"
        case .experience: return "自身の体験を共有する投稿"
        case .failure: return "失敗から得た学びを伝える投稿"
        case .promotion: return "商品・サービスを告知する投稿"
        case .question: return "フォロワーへ問いかける投稿"
        case .achievement: return "成果や実績を紹介する投稿"
        case .other: return "上記に当てはまらない投稿"
        }
    }

    /// UIで用いるSF Symbols名（暫定。UIフェーズで調整可）。
    var symbolName: String {
        switch self {
        case .empathy: return "heart"
        case .knowHow: return "lightbulb"
        case .experience: return "book"
        case .failure: return "exclamationmark.triangle"
        case .promotion: return "megaphone"
        case .question: return "questionmark.circle"
        case .achievement: return "star"
        case .other: return "ellipsis.circle"
        }
    }
}
