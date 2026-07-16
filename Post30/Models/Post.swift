//
//  Post.swift
//  Post30
//
//  1件のSNS投稿を表すモデル。
//
//  設計方針:
//  - 現段階では SwiftData マクロ(@Model)は使用しない。
//    Phase 8 で永続化を導入する際、この final class へ @Model を付与し
//    @Relationship を追加するだけで移行できる構造にしている。
//  - 参照型（class）にすることで、SwiftData のモデルオブジェクトと
//    同じ参照セマンティクスを今から再現しておく。
//  - 親子関係は「単方向」にする。MonthPlan が posts を保持し、
//    Post は所属先を monthPlanID(UUID) で保持する。
//    weak な親オブジェクト参照は持たない（循環参照・予期しない解放を避け、
//    SwiftData 移行時は @Relationship の inverse に自然に置き換えられる）。
//

import Foundation

/// 1件の投稿。
final class Post: Identifiable {
    /// 一意な識別子。
    let id: UUID
    /// 投稿予定日（「日」を表す。時刻は scheduledTime で保持）。
    var scheduledDate: Date
    /// 投稿予定の時刻（任意）。時分のみを保持し、日付とは独立させる。
    var scheduledTime: DateComponents?
    /// 投稿先SNS。
    var platform: SocialPlatform
    /// 投稿カテゴリ。
    var category: PostCategory
    /// 投稿本文（編集可能）。
    var content: String
    /// ステータス。
    var status: PostStatus
    /// 作成日時。
    var createdAt: Date
    /// 更新日時。
    var updatedAt: Date
    /// 実際に投稿済みにした日時（任意）。
    var publishedAt: Date?
    /// メモ（任意）。
    var memo: String?

    /// 所属する月次計画の識別子（単方向参照）。
    /// MonthPlan.addPost 時に設定される。未所属なら nil。
    var monthPlanID: UUID?

    init(
        id: UUID = UUID(),
        scheduledDate: Date,
        scheduledTime: DateComponents? = nil,
        platform: SocialPlatform = .threads,
        category: PostCategory = .other,
        content: String = "",
        status: PostStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        publishedAt: Date? = nil,
        memo: String? = nil,
        monthPlanID: UUID? = nil
    ) {
        self.id = id
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.platform = platform
        self.category = category
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.publishedAt = publishedAt
        self.memo = memo
        self.monthPlanID = monthPlanID
    }

    // MARK: - 予定日時

    /// scheduledDate（日）と scheduledTime（時・分）を組み合わせた予定日時。
    /// time が無い、または hour/minute が欠落・不正な場合は nil を返す（クラッシュしない）。
    /// scheduledDate と同じカレンダー基準で合成するため、不自然なタイムゾーン変換は行わない。
    func scheduledDateTime(calendar: Calendar = .current) -> Date? {
        guard let time = scheduledTime,
              let hour = time.hour,
              let minute = time.minute else {
            return nil
        }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: scheduledDate)
    }

    /// 表示用の時刻文字列（例 "08:00"）。時刻が無い/不正なら nil。
    var scheduledTimeText: String? {
        guard let time = scheduledTime,
              let hour = time.hour,
              let minute = time.minute,
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Hashable / Equatable（id ベースの同一性）

// ナビゲーション経路などで型を値として扱えるよう、id による同一性を与える。
extension Post: Hashable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
