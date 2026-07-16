//
//  PostGenerationViewModelTests.swift
//  Post30Tests
//
//  投稿生成フローのロジック検証。VM は @MainActor のため各テストも @MainActor。
//

import XCTest
@testable import Post30

@MainActor
final class PostGenerationViewModelTests: XCTestCase {

    private let calendar = Calendar.current

    private func makeVM(plan: MonthPlan? = MonthPlan(
        title: "空", year: 2026, month: 8, startDate: Date(), endDate: Date()
    )) -> PostGenerationViewModel {
        PostGenerationViewModel(
            plan: plan,
            service: MockPostGenerationService(perPostDelayNanoseconds: 0),
            calendar: calendar
        )
    }

    private func fillRequired(_ vm: PostGenerationViewModel) {
        vm.businessType = "Web制作"
        vm.serviceName = "ホームページ制作"
        vm.targetAudience = "個人事業主"
    }

    // 必須が空なら Step1 から進めない
    func testCannotProceedWhenRequiredEmpty() {
        let vm = makeVM()
        XCTAssertFalse(vm.isStep1Valid)
        vm.next()
        XCTAssertEqual(vm.step, .businessInfo)
    }

    // 必須が入れば進める
    func testProceedsWhenRequiredFilled() {
        let vm = makeVM()
        fillRequired(vm)
        XCTAssertTrue(vm.isStep1Valid)
        vm.next()
        XCTAssertEqual(vm.step, .conditions)
    }

    // 投稿数 10/20/30 の設定
    func testPostCountOptions() {
        let vm = makeVM()
        for count in [10, 20, 30] {
            vm.postCount = count
            XCTAssertEqual(vm.postCount, count)
        }
    }

    // 確認画面まで進める
    func testCanReachConfirmation() {
        let vm = makeVM()
        fillRequired(vm)
        vm.next() // conditions
        vm.next() // confirmation
        XCTAssertEqual(vm.step, .confirmation)
    }

    // 生成件数が指定数と一致 / 完了状態になる
    func testGenerationProducesRequestedCount() async {
        let plan = MonthPlan(title: "空", year: 2026, month: 8, startDate: Date(), endDate: Date())
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        vm.postCount = 20
        await vm.generate()
        XCTAssertEqual(plan.totalPostCount, 20)
        XCTAssertTrue(vm.isCompleted)
        XCTAssertEqual(vm.generatedCount, 20)
    }

    // 生成投稿の status が scheduled
    func testGeneratedPostsAreScheduled() async {
        let plan = MonthPlan(title: "空", year: 2026, month: 8, startDate: Date(), endDate: Date())
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        await vm.generate()
        XCTAssertTrue(plan.posts.allSatisfy { $0.status == .scheduled })
    }

    // 選択SNSが全投稿へ反映
    func testSelectedPlatformAppliedToAll() async {
        let plan = MonthPlan(title: "空", year: 2026, month: 8, startDate: Date(), endDate: Date())
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        vm.platform = .instagram
        await vm.generate()
        XCTAssertTrue(plan.posts.allSatisfy { $0.platform == .instagram })
    }

    // 開始日から日付が連続する
    func testDatesAreConsecutive() async {
        let plan = MonthPlan(title: "空", year: 2026, month: 8, startDate: Date(), endDate: Date())
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        vm.postCount = 10
        let start = calendar.startOfDay(for: Date())
        vm.startDate = start
        await vm.generate()

        for (index, post) in plan.posts.enumerated() {
            let expected = calendar.date(byAdding: .day, value: index, to: start)!
            XCTAssertTrue(post.scheduledDate.isSameDay(as: expected), "\(index)日目の日付が不正")
        }
    }

    // 予定時刻が全投稿へ反映
    func testScheduledTimeAppliedToAll() async {
        let plan = MonthPlan(title: "空", year: 2026, month: 8, startDate: Date(), endDate: Date())
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        vm.scheduledTime = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!
        await vm.generate()

        XCTAssertTrue(plan.posts.allSatisfy {
            $0.scheduledTime?.hour == 9 && $0.scheduledTime?.minute == 30
        })
    }

    // 同じカテゴリーが過度に連続しない
    func testNoConsecutiveSameCategory() async {
        let plan = MonthPlan(title: "空", year: 2026, month: 8, startDate: Date(), endDate: Date())
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        await vm.generate()
        for index in 1..<plan.posts.count {
            XCTAssertNotEqual(plan.posts[index].category, plan.posts[index - 1].category)
        }
    }

    // 既存投稿を置き換えられる
    func testReplacesExistingPosts() async {
        let plan = SampleData.activePlanWith30Posts()
        let originalIDs = Set(plan.posts.map { $0.id })
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        vm.postCount = 10
        await vm.generate()

        XCTAssertEqual(plan.totalPostCount, 10)
        let newIDs = Set(plan.posts.map { $0.id })
        XCTAssertTrue(newIDs.isDisjoint(with: originalIDs), "古い投稿が残っている")
    }

    // 既存投稿ありは置換確認ダイアログを出す
    func testShowsReplaceDialogWhenPlanHasPosts() {
        let plan = SampleData.activePlanWith30Posts()
        let vm = makeVM(plan: plan)
        fillRequired(vm)
        vm.requestGeneration()
        XCTAssertTrue(vm.showReplaceDialog)
    }

    // キャンセルで確認画面へ戻る
    func testCancelReturnsToConfirmation() {
        let vm = makeVM()
        fillRequired(vm)
        vm.cancelGeneration()
        XCTAssertEqual(vm.step, .confirmation)
        XCTAssertEqual(vm.phase, .idle)
    }
}
