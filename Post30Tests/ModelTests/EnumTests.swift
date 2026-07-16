//
//  EnumTests.swift
//  Post30Tests
//
//  各列挙型の表示名等の検証。
//

import XCTest
@testable import Post30

final class EnumTests: XCTestCase {

    // 8. 各列挙型の日本語表示名が空文字ではない
    func testPostStatusDisplayNamesAreNotEmpty() {
        for status in PostStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty, "\(status) の表示名が空")
        }
    }

    func testMonthPlanStatusDisplayNamesAreNotEmpty() {
        for status in MonthPlanStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty, "\(status) の表示名が空")
        }
    }

    func testSocialPlatformValuesAreNotEmpty() {
        for platform in SocialPlatform.allCases {
            XCTAssertFalse(platform.displayName.isEmpty, "\(platform) の表示名が空")
            XCTAssertFalse(platform.symbolName.isEmpty, "\(platform) のSF Symbolsが空")
            XCTAssertFalse(platform.identifier.isEmpty, "\(platform) の識別子が空")
        }
    }

    func testPostCategoryValuesAreNotEmpty() {
        for category in PostCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category) の表示名が空")
            XCTAssertFalse(category.summary.isEmpty, "\(category) の説明が空")
            XCTAssertFalse(category.symbolName.isEmpty, "\(category) のSF Symbolsが空")
        }
    }
}
