//
//  PostListView.swift
//  Post30
//
//  投稿一覧画面。検索バー（UIのみ）・フィルター・投稿カードのリスト。
//  セルタップで編集プレースホルダへ遷移する構造を用意する（本格実装は Phase 5）。
//

import SwiftUI

struct PostListView: View {
    @State private var viewModel: PostListViewModel
    private let store: PersistenceStore?
    private let onRequestGeneration: () -> Void

    init(
        viewModel: PostListViewModel,
        store: PersistenceStore? = nil,
        onRequestGeneration: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.store = store
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
            .navigationTitle("投稿一覧")
            .searchable(text: $vm.searchText, prompt: "投稿を検索")
            .navigationDestination(for: PostListViewModel.Route.self) { route in
                switch route {
                case .edit(let post):
                    PostEditorView(viewModel: PostEditorViewModel(post: post, store: store))
                case .generate:
                    GeneratePlaceholderView()
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

    private var emptyState: some View {
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

// MARK: - 最小プレースホルダ

/// 30日分生成のプレースホルダ（本格実装は Phase 5）。
private struct GeneratePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "30日分の投稿を作成",
            systemImage: "sparkles",
            description: Text("生成機能は今後のフェーズで実装します。")
        )
        .navigationTitle("AIで30日分の投稿を作成")
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
