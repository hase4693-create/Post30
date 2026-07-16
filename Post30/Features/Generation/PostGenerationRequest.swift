//
//  PostGenerationRequest.swift
//  Post30
//
//  投稿生成の入力条件（画面入力用の軽量な値型）。永続データモデルではない。
//

import Foundation

/// 文章の雰囲気。
enum PostTone: String, CaseIterable, Identifiable {
    case friendly, polite, professional, casual, passionate, simple
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .friendly: return "親しみやすい"
        case .polite: return "丁寧"
        case .professional: return "専門的"
        case .casual: return "カジュアル"
        case .passionate: return "熱量が高い"
        case .simple: return "シンプル"
        }
    }
}

/// 宣伝投稿の割合。
enum PromotionLevel: String, CaseIterable, Identifiable {
    case few, standard, many
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .few: return "少なめ"
        case .standard: return "標準"
        case .many: return "多め"
        }
    }
}

/// 投稿生成の入力条件。
struct PostGenerationRequest {
    // Step 1: 事業情報
    var businessType: String
    var serviceName: String
    var targetAudience: String
    var postingGoal: String
    var strength: String

    // Step 2: 投稿条件
    var platform: SocialPlatform
    var postCount: Int
    var tone: PostTone
    var promotionLevel: PromotionLevel
    var prohibitedExpressions: String
    var startDate: Date
    var scheduledTime: Date
}
