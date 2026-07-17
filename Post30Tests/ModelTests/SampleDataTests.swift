//
//  SampleDataTests.swift
//  Post30Tests
//
//  サンプルデータの検証。
//

import XCTest
@testable import Post30

final class SampleDataTests: XCTestCase {

    // 9. サンプルMonthPlanに30件の投稿が含まれる
    func testActivePlanHas30Posts() {
        let plan = SampleData.activePlanWith30Posts()
        XCTAssertEqual(plan.totalPostCount, 30)
    }

    func testEmptyPlanHasNoPosts() {
        XCTAssertEqual(SampleData.emptyPlan().totalPostCount, 0)
    }

    func testCompletedPlanIsFullyPublished() {
        let plan = SampleData.completedPlan()
        XCTAssertEqual(plan.totalPostCount, 30)
        XCTAssertEqual(plan.publishedCount, 30)
        XCTAssertEqual(plan.publishedProgressRate, 1.0, accuracy: 0.0001)
    }

    func testChildPostsReferenceParentPlan() {
        let plan = SampleData.activePlanWith30Posts()
        // 親子関係: すべての投稿が親計画を参照している。
        XCTAssertTrue(plan.posts.allSatisfy { $0.plan === plan })
    }
}
