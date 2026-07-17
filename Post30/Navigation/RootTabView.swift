//
//  RootTabView.swift
//  Post30
//
//  アプリのルート。SwiftData を Single Source of Truth として、
//  ホーム・投稿一覧・編集・生成が同じ永続 MonthPlan を参照する。
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    enum Tab: Hashable {
        case home, calendar, postList, settings
    }

    @Environment(\.modelContext) private var modelContext

    @State private var selection: Tab = .home
    @State private var isPresentingGeneration = false

    @State private var store: PersistenceStore?
    @State private var homeViewModel: HomeViewModel?
    @State private var postListViewModel: PostListViewModel?

    var body: some View {
        Group {
            if let homeViewModel, let postListViewModel, let store {
                tabView(homeViewModel: homeViewModel, postListViewModel: postListViewModel, store: store)
            } else {
                ProgressView()
                    .task { setup() }
            }
        }
    }

    // MARK: - セットアップ（シード＋現在の計画取得）

    @MainActor
    private func setup() {
        guard homeViewModel == nil else { return }
        let store = PersistenceStore(context: modelContext)
        let plan = try? {
            try store.seedIfNeeded()
            return try store.currentMonthPlan()
        }()
        self.store = store
        self.homeViewModel = HomeViewModel(
            plan: plan,
            clipboardService: SystemClipboardService(),
            store: store
        )
        self.postListViewModel = PostListViewModel(plan: plan)
    }

    private func tabView(
        homeViewModel: HomeViewModel,
        postListViewModel: PostListViewModel,
        store: PersistenceStore
    ) -> some View {
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
                store: store,
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
            PostGenerationView(
                viewModel: makeGenerationViewModel(store: store, homeViewModel: homeViewModel)
            )
        }
    }

    @MainActor
    private func makeGenerationViewModel(
        store: PersistenceStore,
        homeViewModel: HomeViewModel
    ) -> PostGenerationViewModel {
        // 生成対象の計画：現在のもの。無ければ空の計画を作成する。
        let plan = (try? store.currentMonthPlan()) ?? (try? store.createEmptyMonthPlan())
        return PostGenerationViewModel(
            plan: plan,
            service: MockPostGenerationService(),
            store: store,
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
        .modelContainer(for: [MonthPlan.self, Post.self], inMemory: true)
}
#endif
