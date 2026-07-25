//
//  PostStatusBadgeModelTests.swift
//  Post30Tests
//
//  ステータスバッジ表示モデルの検証（純ロジック・日付非依存）。
//

import XCTest
@testable import Post30

final class PostStatusBadgeModelTests: XCTestCase {

    // 1〜3. 表示名（PostStatus.displayName と一致）
    func testTitles() {
        XCTAssertEqual(PostStatusBadgeModel(status: .draft).title, "下書き")
        XCTAssertEqual(PostStatusBadgeModel(status: .scheduled).title, "予約済み")
        XCTAssertEqual(PostStatusBadgeModel(status: .published).title, "投稿済み")
        XCTAssertEqual(PostStatusBadgeModel(status: .skipped).title, "見送り")
    }

    // PostStatus.displayName とバッジ文言が一致（表記揺れなし）
    func testTitleMatchesStatusDisplayName() {
        for status in PostStatus.allCases {
            XCTAssertEqual(PostStatusBadgeModel(status: status).title, status.displayName)
        }
    }

    // アイコンが各状態に対応する
    func testSystemImageNames() {
        XCTAssertEqual(PostStatusBadgeModel(status: .draft).systemImageName, "doc.text")
        XCTAssertEqual(PostStatusBadgeModel(status: .scheduled).systemImageName, "clock")
        XCTAssertEqual(PostStatusBadgeModel(status: .published).systemImageName, "checkmark.circle.fill")
        XCTAssertEqual(PostStatusBadgeModel(status: .skipped).systemImageName, "minus.circle")
    }

    // 4. 投稿済み以外が誤って「投稿済み」にフォールバックしない
    func testNoPublishedFallback() {
        for status in PostStatus.allCases where status != .published {
            XCTAssertNotEqual(PostStatusBadgeModel(status: status).title, "投稿済み")
            XCTAssertNotEqual(PostStatusBadgeModel(status: status).systemImageName, "checkmark.circle.fill")
        }
    }

    // 5. 表示名は状態のみで決まり、日付に依存しない（決定的）
    func testDeterministicByStatusOnly() {
        for status in PostStatus.allCases {
            XCTAssertEqual(PostStatusBadgeModel(status: status), PostStatusBadgeModel(status: status))
        }
    }

    // 表示名は空でない
    func testTitlesAreNotEmpty() {
        for status in PostStatus.allCases {
            XCTAssertFalse(PostStatusBadgeModel(status: status).title.isEmpty)
        }
    }
}
