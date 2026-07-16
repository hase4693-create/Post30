//
//  MockPostGenerationServiceTests.swift
//  Post30Tests
//
//  モック生成サービスの検証。
//

import XCTest
@testable import Post30

final class MockPostGenerationServiceTests: XCTestCase {

    private let calendar = Calendar.current

    private func makeRequest(postCount: Int) -> PostGenerationRequest {
        PostGenerationRequest(
            businessType: "Web制作",
            serviceName: "ホームページ制作",
            targetAudience: "個人事業主",
            postingGoal: "問い合わせ獲得",
            strength: "分かりやすさ",
            platform: .threads,
            postCount: postCount,
            tone: .friendly,
            promotionLevel: .standard,
            prohibitedExpressions: "",
            startDate: calendar.startOfDay(for: Date()),
            scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        )
    }

    private func generate(count: Int) async -> [Post] {
        let service = MockPostGenerationService(perPostDelayNanoseconds: 0)
        return (try? await service.generatePosts(request: makeRequest(postCount: count), onProgress: { _ in })) ?? []
    }

    func testGenerates10() async {
        let posts = await generate(count: 10)
        XCTAssertEqual(posts.count, 10)
    }

    func testGenerates20() async {
        let posts = await generate(count: 20)
        XCTAssertEqual(posts.count, 20)
    }

    func testGenerates30() async {
        let posts = await generate(count: 30)
        XCTAssertEqual(posts.count, 30)
    }

    func testContentIsNotEmpty() async {
        let posts = await generate(count: 30)
        XCTAssertTrue(posts.allSatisfy { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

    func testPostIDsAreUnique() async {
        let posts = await generate(count: 30)
        let ids = Set(posts.map { $0.id })
        XCTAssertEqual(ids.count, posts.count)
    }

    func testCategoryDistributionMatchesTarget() async {
        let posts = await generate(count: 30)
        var counts: [PostCategory: Int] = [:]
        for post in posts { counts[post.category, default: 0] += 1 }

        for target in MockPostGenerationService.targetCounts(for: 30) {
            XCTAssertEqual(counts[target.category] ?? 0, target.count, "\(target.category) の件数が期待と異なる")
        }
    }

    func testNoConsecutiveSameCategory() async {
        let posts = await generate(count: 30)
        for index in 1..<posts.count {
            XCTAssertNotEqual(posts[index].category, posts[index - 1].category, "同一カテゴリーが連続している")
        }
    }
}
