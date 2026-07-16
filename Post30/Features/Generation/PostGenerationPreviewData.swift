//
//  PostGenerationPreviewData.swift
//  Post30
//
//  投稿生成 Preview 専用データ（DEBUG 限定・本番 SampleData とは分離）。
//

#if DEBUG
import Foundation

@MainActor
enum PostGenerationPreviewData {

    private static func base() -> PostGenerationViewModel {
        PostGenerationViewModel(
            plan: nil,
            service: MockPostGenerationService(perPostDelayNanoseconds: 0)
        )
    }

    private static func filled(_ vm: PostGenerationViewModel) -> PostGenerationViewModel {
        vm.businessType = "Web制作"
        vm.serviceName = "個人事業主向けホームページ制作"
        vm.targetAudience = "ホームページを持っていない個人事業主"
        vm.postingGoal = "認知拡大と問い合わせ獲得"
        vm.strength = "専門用語を使わず、分かりやすく説明できる"
        vm.prohibitedExpressions = "煽るような表現"
        return vm
    }

    static func step1Empty() -> PostGenerationViewModel {
        base()
    }

    static func step1Filled() -> PostGenerationViewModel {
        filled(base())
    }

    static func step(_ step: PostGenerationViewModel.Step) -> PostGenerationViewModel {
        let vm = filled(base())
        vm.previewConfigure(step: step)
        return vm
    }

    static func generating(current: Int, total: Int) -> PostGenerationViewModel {
        let vm = filled(base())
        vm.previewConfigure(step: .generation, phase: .generating(current: current, total: total))
        return vm
    }

    static func completed(count: Int) -> PostGenerationViewModel {
        let vm = filled(base())
        vm.previewConfigure(step: .generation, phase: .completed, generatedCount: count)
        return vm
    }
}
#endif
