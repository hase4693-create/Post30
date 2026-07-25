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
    @State private var calendarViewModel: CalendarViewModel?

    var body: some View {
        Group {
            if let homeViewModel, let postListViewModel, let calendarViewModel, let store {
                tabView(
                    homeViewModel: homeViewModel,
                    postListViewModel: postListViewModel,
                    calendarViewModel: calendarViewModel,
                    store: store
                )
            } else {
                ProgressView()
                    .task { setup() }
            }
        }
    }

    // MARK: - セットアップ（現在の計画取得）

    @MainActor
    private func setup() {
        guard homeViewModel == nil else { return }
        let store = PersistenceStore(context: modelContext)
        // Version 1.0 は初回シード（サンプル投稿）を行わない＝空スタート。
        // 全画面で同じ計画を共有し生成/編集結果を即時反映させるため、
        // 計画が無ければ「投稿0件の空の計画」だけを用意する。
        let plan = (try? store.currentMonthPlan()) ?? (try? store.createEmptyMonthPlan())
        self.store = store
        self.homeViewModel = HomeViewModel(
            plan: plan,
            clipboardService: SystemClipboardService(),
            store: store
        )
        self.postListViewModel = PostListViewModel(plan: plan)
        self.calendarViewModel = CalendarViewModel(plan: plan)
    }

    private func tabView(
        homeViewModel: HomeViewModel,
        postListViewModel: PostListViewModel,
        calendarViewModel: CalendarViewModel,
        store: PersistenceStore
    ) -> some View {
        TabView(selection: $selection) {
            HomeView(
                viewModel: homeViewModel,
                store: store,
                onShowCalendar: { selection = .calendar },
                onRequestGeneration: { isPresentingGeneration = true }
            )
            .tabItem { Label("ホーム", systemImage: "house") }
            .tag(Tab.home)

            CalendarView(viewModel: calendarViewModel, store: store)
                .tabItem { Label("カレンダー", systemImage: "calendar") }
                .tag(Tab.calendar)

            PostListView(
                viewModel: postListViewModel,
                store: store,
                onRequestGeneration: { isPresentingGeneration = true }
            )
            .tabItem { Label("投稿一覧", systemImage: "list.bullet") }
            .tag(Tab.postList)

            SettingsView()
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
