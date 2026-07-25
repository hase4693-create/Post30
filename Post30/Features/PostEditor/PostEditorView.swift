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
                section("状態") {
                    HStack(spacing: Theme.Spacing.small) {
                        // 一覧と同じ共通バッジを再利用（文言・見た目を統一）。
                        PostStatusBadge(status: viewModel.status)
                        Spacer()
                        Text("投稿日を変えても状態は変わりません")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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
        .alert(
            "データを保存できませんでした。もう一度お試しください。",
            isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.saveError = nil }
        }
        .confirmationDialog(
            "投稿済みにしますか？",
            isPresented: $vm.showMarkPublishedDialog,
            titleVisibility: .visible
        ) {
            // 破壊的操作ではないため role: .destructive は使わない。
            Button("投稿済みにする") {
                // 編集内容を含めて1回で保存。成功時のみ閉じる。
                if viewModel.confirmMarkAsPublished() {
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この投稿を投稿済みとして記録します。")
        }
    }

    // MARK: - 保存バー

    private var saveBar: some View {
        VStack(spacing: Theme.Spacing.small) {
            // 未投稿（下書き・予約済み）のときだけ「投稿済みにする」を表示。
            if viewModel.canMarkAsPublished {
                markPublishedButton
            }

            PrimaryButton(title: "保存する", fill: .gradient) {
                // 保存成功時のみ前画面へ戻る。失敗時は画面を閉じずエラー表示。
                if viewModel.save() {
                    dismiss()
                }
            }
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1.0 : 0.5)
        }
        .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Color.screenBackground)
    }

    /// 「投稿済みにする」（非破壊・成功系の見た目）。
    private var markPublishedButton: some View {
        Button {
            viewModel.requestMarkAsPublished()
        } label: {
            Label("投稿済みにする", systemImage: "checkmark.circle")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.Layout.primaryButtonHeight)
                .foregroundStyle(Theme.Color.success)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.buttonCornerRadius)
                        .stroke(Theme.Color.success, lineWidth: 1.5)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1.0 : 0.5)
        .accessibilityLabel("投稿済みにする")
        .accessibilityHint("この投稿を投稿済みとして記録します")
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
    .previewPersistence()
}

#Preview("本文なし") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.emptyContent())
    }
    .previewPersistence()
}

#Preview("長文") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.longContent())
    }
    .previewPersistence()
}

#Preview("ダークモード") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.normal())
    }
    .preferredColorScheme(.dark)
    .previewPersistence()
}

#Preview("大きい文字サイズ") {
    NavigationStack {
        PostEditorView(viewModel: PostEditorPreviewData.normal())
    }
    .environment(\.dynamicTypeSize, .accessibility3)
    .previewPersistence()
}
#endif
