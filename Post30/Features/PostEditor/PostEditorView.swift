//
//  PostEditorView.swift
//  Post30
//
//  投稿編集画面。入力欄はカードUI、保存ボタンは下部固定。
//  未保存変更がある状態で戻ると破棄確認ダイアログを表示する。
//

import SwiftUI

struct PostEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PostEditorViewModel
    @State private var showDiscardDialog = false

    init(viewModel: PostEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var vm = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                section("カテゴリー") {
                    Picker("カテゴリー", selection: $vm.category) {
                        ForEach(PostCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                section("投稿先SNS") {
                    Picker("投稿先SNS", selection: $vm.platform) {
                        ForEach(SocialPlatform.allCases) { platform in
                            Text(platform.displayName).tag(platform)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                section("投稿日") {
                    DatePicker("投稿日", selection: $vm.scheduledDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                section("投稿時刻") {
                    DatePicker("投稿時刻", selection: $vm.scheduledTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                section("投稿本文") {
                    TextEditor(text: $vm.content)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel("投稿本文")
                    if !viewModel.isContentValid {
                        Text("本文を入力してください")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                section("メモ") {
                    TextEditor(text: $vm.memo)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel("メモ")
                }
            }
            .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
            .padding(.vertical, Theme.Spacing.large)
        }
        .background(Theme.Color.screenBackground.ignoresSafeArea())
        .navigationTitle("投稿を編集")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleBack()
                } label: {
                    Label("戻る", systemImage: "chevron.left")
                }
                .accessibilityLabel("戻る")
            }
        }
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
        .confirmationDialog(
            "変更を破棄しますか？",
            isPresented: $showDiscardDialog,
            titleVisibility: .visible
        ) {
            Button("破棄する", role: .destructive) { dismiss() }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - 保存バー

    private var saveBar: some View {
        PrimaryButton(title: "保存する", fill: .gradient) {
            viewModel.save()
            dismiss()
        }
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1.0 : 0.5)
        .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Color.screenBackground)
    }

    // MARK: - 入力欄カード

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func handleBack() {
        if viewModel.hasUnsavedChanges {
            showDiscardDialog = true
        } else {
            dismiss()
        }
    }
}

#if DEBUG
#Preview("通常") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.normal())
    }
}

#Preview("本文なし") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.emptyContent())
    }
}

#Preview("長文") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.longContent())
    }
}

#Preview("ダークモード") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.normal())
    }
    .preferredColorScheme(.dark)
}

#Preview("大きい文字サイズ") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.normal())
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
