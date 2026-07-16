//
//  RootTabView.swift
//  Post30
//
//  アプリのルート。ホーム／カレンダー／投稿一覧／設定の4タブ。
//  投稿生成ウィザードは全画面カバーで提示する。
//

import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable {
        case home, calendar, postList, settings
    }

    @State private var selection: Tab = .home
    @State private var isPresentingGeneration = false

    // ホームと投稿一覧で同じ MonthPlan（=同じ Post 参照）を共有することで、
    // 編集・生成の結果がメモリ上で即時反映される。SwiftData 接続は後続フェーズ。
    private let sharedPlan: MonthPlan
    private let homeViewModel: HomeViewModel
    private let postListViewModel: PostListViewModel

    init(plan: MonthPlan? = nil) {
        let sharedPlan = plan ?? SampleData.activePlanWith30Posts()
        self.sharedPlan = sharedPlan
        self.homeViewModel = HomeViewModel(
            plan: sharedPlan,
            clipboardService: SystemClipboardService()
        )
        self.postListViewModel = PostListViewModel(plan: sharedPlan)
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(
                viewModel: homeViewModel,
                onShowCalendar: { selection = .calendar },
                onRequestGeneration: { isPresentingGeneration = true }
            )
            .tabItem { Label("ホーム", systemImage: "house") }
            .tag(Tab.home)

            CalendarPlaceholderView()
                .tabItem { Label("カレンダー", systemImage: "calendar") }
                .tag(Tab.calendar)

            PostListView(
                viewModel: postListViewModel,
                onRequestGeneration: { isPresentingGeneration = true }
            )
            .tabItem { Label("投稿一覧", systemImage: "list.bullet") }
            .tag(Tab.postList)

            SettingsPlaceholderView()
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .tint(Theme.Color.accent)
        .fullScreenCover(isPresented: $isPresentingGeneration) {
            PostGenerationView(viewModel: makeGenerationViewModel())
        }
    }

    @MainActor
    private func makeGenerationViewModel() -> PostGenerationViewModel {
        PostGenerationViewModel(
            plan: sharedPlan,
            service: MockPostGenerationService(),
            onGoToPostList: {
                homeViewModel.reload()
                selection = .postList
                isPresentingGeneration = false
            },
            onGoHome: {
                homeViewModel.reload()
                selection = .home
                isPresentingGeneration = false
            },
            onClose: {
                isPresentingGeneration = false
            }
        )
    }
}

#if DEBUG
#Preview {
    RootTabView()
}
#endif
