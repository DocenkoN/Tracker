import UIKit

struct OnboardingPageModel {
    let title: String
    let backgroundImageName: String
    let emojis: [String]
}

extension OnboardingPageModel {
    static let pages: [OnboardingPageModel] = [
        OnboardingPageModel(
            title: "Отслеживайте только\nто, что хотите",
            backgroundImageName: "backgr_1",
            emojis: ["🥰", "✨"]
        ),
        OnboardingPageModel(
            title: "Даже если это\nне литры воды и йога",
            backgroundImageName: "backgr_2",
            emojis: ["🔥", "🥳"]
        )
    ]
}

