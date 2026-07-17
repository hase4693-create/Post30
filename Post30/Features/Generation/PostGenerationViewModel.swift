//
//  PostGenerationViewModel.swift
//  Post30
//
//  30日分投稿生成フローのロジック（MVVM）。
//  入力保持・ステップ管理・バリデーション・生成進捗・キャンセル・置換確認・
//  MonthPlan への反映・画面遷移トリガを担う。
//

import Foundation
import Observation

@MainActor
@Observable
final class PostGenerationViewModel {

    /// ウィザードのステップ。
    enum Step: Int, CaseIterable {
        case businessInfo = 0
        case conditions = 1
        case confirmation = 2
        case generation = 3

        /// 入力ステップの進捗表示用（1〜3）。生成ステップは対象外。
        var inputStepNumber: Int { rawValue + 1 }

        var title: String {
            switch self {
            case .businessInfo: return "事業情報"
            case .conditions: return "投稿条件"
            case .confirmation: return "入力内容の確認"
            case .generation: return "生成"
            }
        }
    }

    /// 生成フェーズ。
    enum Phase: Equatable {
        case idle
        case generating(current: Int, total: Int)
        case completed
    }

    // MARK: - 入力（Step 1）
    var businessType: String = ""
    var serviceName: String = ""
    var targetAudience: String = ""
    var postingGoal: String = ""
    var strength: String = ""

    // MARK: - 入力（Step 2）
    var platform: SocialPlatform = .threads
    var postCount: Int = 30
    var tone: PostTone = .friendly
    var promotionLevel: PromotionLevel = .standard
    var prohibitedExpressions: String = ""
    var startDate: Date
    var scheduledTime: Date

    // MARK: - 状態
    private(set) var step: Step = .businessInfo
    private(set) var phase: Phase = .idle
    var showReplaceDialog: Bool = false
    private(set) var generatedCount: Int = 0

    /// 投稿数の選択肢。
    let postCountOptions: [Int] = [10, 20, 30]

    // MARK: - 依存
    private let plan: MonthPlan?
    private let service: PostGenerationService
    private let store: PersistenceStore?
    private let calendar: Calendar
    private let now: () -> Date
    private let onGoToPostList: () -> Void
    private let onGoHome: () -> Void
    private let onClose: () -> Void

    /// 保存エラー表示用（nil なら非表示）。
    var saveError: String?

    private var generationTask: Task<Void, Never>?

    init(
        plan: MonthPlan?,
        service: PostGenerationService = MockPostGenerationService(),
        store: PersistenceStore? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        onGoToPostList: @escaping () -> Void = {},
        onGoHome: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) {
        self.plan = plan
        self.service = service
        self.store = store
        self.calendar = calendar
        self.now = now
        self.onGoToPostList = onGoToPostList
        self.onGoHome = onGoHome
        self.onClose = onClose
        self.startDate = calendar.startOfDay(for: now())
        self.scheduledTime = calendar.date(
            bySettingHour: 8, minute: 0, second: 0, of: now()
        ) ?? now()
    }

    // MARK: - バリデーション

    /// Step 1 の必須項目（業種・商品/サービス・ターゲット）が入力済みか。
    var isStep1Valid: Bool {
        !businessType.trimmed.isEmpty &&
        !serviceName.trimmed.isEmpty &&
        !targetAudience.trimmed.isEmpty
    }

    /// 現在のステップから次へ進めるか。
    var canProceed: Bool {
        switch step {
        case .businessInfo: return isStep1Valid
        case .conditions: return true
        case .confirmation: return true
        case .generation: return false
        }
    }

    var isGenerating: Bool {
        if case .generating = phase { return true }
        return false
    }

    var isCompleted: Bool { phase == .completed }

    // MARK: - ステップ移動

    func next() {
        switch step {
        case .businessInfo:
            if isStep1Valid { step = .conditions }
        case .conditions:
            step = .confirmation
        case .confirmation:
            requestGeneration()
        case .generation:
            break
        }
    }

    func back() {
        switch step {
        case .businessInfo:
            onClose()
        case .conditions:
            step = .businessInfo
        case .confirmation:
            step = .conditions
        case .generation:
            cancelGeneration()
        }
    }

    /// 画面を閉じる（ツールバーの閉じるボタン等）。
    func close() {
        generationTask?.cancel()
        onClose()
    }

    // MARK: - 生成開始（置換確認）

    /// 「この内容で作成」。既存投稿があれば置換確認、なければ生成開始。
    func requestGeneration() {
        if (plan?.totalPostCount ?? 0) > 0 {
            showReplaceDialog = true
        } else {
            beginGeneration()
        }
    }

    func confirmReplace() {
        showReplaceDialog = false
        beginGeneration()
    }

    func cancelReplace() {
        showReplaceDialog = false
    }

    // MARK: - 生成

    private func beginGeneration() {
        step = .generation
        generationTask = Task { [weak self] in
            await self?.generate()
        }
    }

    /// 生成本体（テストからは await で直接呼べる）。
    func generate() async {
        let request = makeRequest()
        phase = .generating(current: 0, total: request.postCount)
        do {
            let posts = try await service.generatePosts(request: request) { [weak self] count in
                Task { @MainActor in
                    self?.updateProgress(count: count, total: request.postCount)
                }
            }
            applyToPlan(posts, request: request)
            generatedCount = posts.count
            phase = .completed
        } catch {
            // キャンセル等：生成前（確認画面）へ戻す
            phase = .idle
            step = .confirmation
        }
    }

    private func updateProgress(count: Int, total: Int) {
        guard isGenerating else { return }
        phase = .generating(current: count, total: total)
    }

    /// 生成をキャンセルし、生成前の画面へ戻す。
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        phase = .idle
        step = .confirmation
    }

    // MARK: - MonthPlan への反映（置き換え）

    private func applyToPlan(_ posts: [Post], request: PostGenerationRequest) {
        guard let plan else { return }
        let startDay = calendar.startOfDay(for: request.startDate)
        let components = calendar.dateComponents([.year, .month], from: startDay)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let endDate = calendar.date(byAdding: .day, value: max(request.postCount - 1, 0), to: startDay) ?? startDay

        plan.title = "\(year)年\(month)月の投稿計画"
        plan.year = year
        plan.month = month
        plan.startDate = startDay
        plan.endDate = endDate
        plan.status = .active
        plan.updatedAt = now()

        if let store {
            // 永続層：旧Postを削除して置き換え、保存する。
            do {
                try store.replacePosts(in: plan, with: posts)
            } catch {
                saveError = "データを保存できませんでした。もう一度お試しください。"
            }
        } else {
            // テスト等：メモリ上のみ置き換え。
            plan.replacePosts(posts)
        }
    }

    // MARK: - 完了画面用の表示値

    var completedPlatformName: String { platform.displayName }

    func startDateText() -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.setLocalizedDateFormatFromTemplate("yMMMdEEE")
        return formatter.string(from: startDate)
    }

    func scheduledTimeText() -> String {
        let comps = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }

    // MARK: - 完了後の遷移

    func goToPostList() { onGoToPostList() }
    func goHome() { onGoHome() }

    // MARK: - リクエスト生成

    func makeRequest() -> PostGenerationRequest {
        PostGenerationRequest(
            businessType: businessType.trimmed,
            serviceName: serviceName.trimmed,
            targetAudience: targetAudience.trimmed,
            postingGoal: postingGoal.trimmed,
            strength: strength.trimmed,
            platform: platform,
            postCount: postCount,
            tone: tone,
            promotionLevel: promotionLevel,
            prohibitedExpressions: prohibitedExpressions.trimmed,
            startDate: startDate,
            scheduledTime: scheduledTime
        )
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#if DEBUG
extension PostGenerationViewModel {
    /// Preview 専用：ステップ/フェーズを直接設定する（同一ファイル内なので private(set) を更新可）。
    func previewConfigure(step: Step, phase: Phase = .idle, generatedCount: Int = 0) {
        self.step = step
        self.phase = phase
        self.generatedCount = generatedCount
    }
}
#endif
