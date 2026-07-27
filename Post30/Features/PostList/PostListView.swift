//
//  PostListView.swift
//  Post30
//
//  投稿一覧画面。フィルター・投稿カードのリスト。
//  セルタップで正式な投稿編集画面へ遷移する。
//

import SwiftUI

struct PostListView: View {
    @State private var viewModel: PostListViewModel
    private let store: PersistenceStore?
    private let title: String
    /// シート等で表示する際の「閉じる」処理（nil の場合はボタンを出さない）。
    private let onClose: (() -> Void)?
    /// 全体が0件のときに生成CTAを表示するか（通常一覧=true／今月の投稿シート=false）。
    private let showsGenerateCTA: Bool
    private let onRequestGeneration: () -> Void

    init(
        viewModel: PostListViewModel,
        store: PersistenceStore? = nil,
        title: String = "投稿一覧",
        onClose: (() -> Void)? = nil,
        showsGenerateCTA: Bool = true,
        onRequestGeneration: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.store = store
        self.title = title
        self.onClose = onClose
        self.showsGenerateCTA = showsGenerateCTA
        self.onRequestGeneration = onRequestGeneration
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack(path: $vm.path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Layout.cardSpacing) {
                    filterPicker

                    if viewModel.isEmpty {
                        emptyState
                    } else if viewModel.filteredPosts.isEmpty {
                        noMatchState
                    } else {
                        ForEach(viewModel.filteredPosts) { post in
                            PostRowCard(
                                post: post,
                                dateText: viewModel.scheduledDateText(for: post),
                                onTap: { viewModel.requestEdit(post) }
                            )
                        }
                    }
                }
                .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
                .padding(.vertical, Theme.Spacing.medium)
            }
            .background(Theme.Color.screenBackground.ignoresSafeArea())
            .navigationTitle(title)
            .toolbar {
                if let onClose {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("閉じる") { onClose() }
                    }
                }
            }
            .navigationDestination(for: PostListViewModel.Route.self) { route in
                switch route {
                case .edit(let post):
                    PostEditorView(viewModel: PostEditorViewModel(post: post, store: store))
                }
            }
        }
    }

    // MARK: - フィルター

    private var filterPicker: some View {
        Picker("フィルター", selection: $viewModel.selectedFilter) {
            ForEach(PostListViewModel.Filter.allCases) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("投稿フィルター")
    }

    // MARK: - 空状態

    @ViewBuilder
    private var emptyState: some View {
        if showsGenerateCTA {
            // 通常一覧：計画そのものが空 → 生成CTAを表示（接続済み）。
            generateEmptyState
        } else {
            // 今月の投稿シート：当月0件 → 操作のない情報表示のみ（無反応CTAを出さない）。
            ContentUnavailableView(
                "今月の投稿はありません",
                systemImage: "calendar",
                description: Text("今月に予定されている投稿はまだありません。")
            )
            .padding(.top, Theme.Spacing.large)
        }
    }

    private var generateEmptyState: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Color.accent)
                .accessibilityHidden(true)
            Text("投稿がありません")
                .font(.headline)
            PrimaryButton(
                title: "AIで30日分の投稿を作成",
                leadingSystemImage: "sparkles",
                trailingSystemImage: "chevron.right",
                fill: .gradient
            ) {
                onRequestGeneration()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.large * 2)
    }

    private var noMatchState: some View {
        Text("該当する投稿がありません")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, Theme.Spacing.large * 2)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("1. 投稿30件") {
    PostListView(viewModel: PostListPreviewData.viewModel(filter: .all))
        .previewPersistence()
}

#Preview("2. 投稿0件") {
    PostListView(viewModel: PostListPreviewData.emptyViewModel())
        .previewPersistence()
}

#Preview("3. 投稿済みだけ") {
    PostListView(viewModel: PostListPreviewData.viewModel(filter: .published))
        .previewPersistence()
}

#Preview("4. 未投稿だけ") {
    PostListView(viewModel: PostListPreviewData.viewModel(filter: .unpublished))
        .previewPersistence()
}

#Preview("5. ダークモード") {
    PostListView(viewModel: PostListPreviewData.viewModel(filter: .all))
        .preferredColorScheme(.dark)
        .previewPersistence()
}

#Preview("6. 大きい文字サイズ") {
    PostListView(viewModel: PostListPreviewData.viewModel(filter: .all))
        .environment(\.dynamicTypeSize, .accessibility3)
        .previewPersistence()
}
#endif
