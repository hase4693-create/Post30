//
//  MonthPlanStatus.swift
//  Post30
//
//  月次計画のステータスを表す列挙型。
//

import Foundation

/// 月次計画（30日運用）の状態。
enum MonthPlanStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    /// 下書き（作成途中）
    case draft
    /// 進行中
    case active
    /// 完了
    case completed
    /// アーカイブ済み
    case archived

    var id: String { rawValue }

    /// 日本語の表示名。
    var displayName: String {
        switch self {
        case .draft: return "下書き"
        case .active: return "進行中"
        case .completed: return "完了"
        case .archived: return "アーカイブ"
        }
    }
}
