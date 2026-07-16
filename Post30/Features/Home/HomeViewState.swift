//
//  HomeViewState.swift
//  Post30
//
//  ホーム画面の表示状態。
//  大分類は loading / content / empty / error のみ。
//  「今日の投稿あり／なし」はケースを増やさず content 内のデータで表現する。
//

import Foundation

/// ホーム画面の表示状態。
enum HomeViewState {
    case loading
    case content(HomeContent)
    case empty
    case error(message: String)
}

/// content 状態で表示するデータ。
struct HomeContent {
    /// 対象の月次計画。
    let plan: MonthPlan
    /// 今日の投稿（無ければ nil）。
    let todayPost: Post?
    /// 今日の投稿が無い場合の、基準日時以降の次回投稿（無ければ nil）。
    let nextPost: Post?
}
