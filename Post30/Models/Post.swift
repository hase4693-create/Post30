//
//  Post.swift
//  Post30
//
//  1件のSNS投稿を表す SwiftData モデル。
//
//  設計方針（Phase 7 / SwiftData 移行）:
//  - @Model で永続化する。列挙型（String, Codable）はそのまま保存できる。
//  - 時刻は DateComponents ではなく scheduledHour/scheduledMinute(Int?) で保存し、
//    従来通り scheduledTime(DateComponents?) として扱える計算プロパティを用意する。
//  - MonthPlan との親子関係は Relationship（inverse: plan）で表現する。
//    以前の monthPlanID は撤去（Relationship に一本化＝二重管理しない）。
//

import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var id: UUID
    var scheduledDate: Date
    /// 予定時刻（時）。未設定なら nil。
    var scheduledHour: Int?
    /// 予定時刻（分）。未設定なら nil。
    var scheduledMinute: Int?
    var platform: SocialPlatform
    var category: PostCategory
    var content: String
    var status: PostStatus
    var createdAt: Date
    var updatedAt: Date
    var publishedAt: Date?
    var memo: String?

    /// 所属する月次計画（親）。MonthPlan.posts の inverse。
    var plan: MonthPlan?

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
        memo: String? = nil
    ) {
        self.id = id
        self.scheduledDate = scheduledDate
        self.scheduledHour = scheduledTime?.hour
        self.scheduledMinute = scheduledTime?.minute
        self.platform = platform
        self.category = category
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.publishedAt = publishedAt
        self.memo = memo
    }

    // MARK: - 時刻の互換アクセサ

    /// 従来通り DateComponents(時・分) として時刻を扱うための計算プロパティ。
    var scheduledTime: DateComponents? {
        get {
            if scheduledHour == nil && scheduledMinute == nil { return nil }
            return DateComponents(hour: scheduledHour, minute: scheduledMinute)
        }
        set {
            scheduledHour = newValue?.hour
            scheduledMinute = newValue?.minute
        }
    }

    // MARK: - 予定日時

    /// scheduledDate（日）と時・分を組み合わせた予定日時。
    /// 時刻が無い/不正な場合は nil を返す（クラッシュしない）。
    func scheduledDateTime(calendar: Calendar = .current) -> Date? {
        guard let scheduledHour, let scheduledMinute else { return nil }
        return calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: scheduledDate)
    }

    /// 表示用の時刻文字列（例 "08:00"）。時刻が無い/不正なら nil。
    var scheduledTimeText: String? {
        guard let scheduledHour, let scheduledMinute,
              (0...23).contains(scheduledHour),
              (0...59).contains(scheduledMinute) else {
            return nil
        }
        return String(format: "%02d:%02d", scheduledHour, scheduledMinute)
    }
}
