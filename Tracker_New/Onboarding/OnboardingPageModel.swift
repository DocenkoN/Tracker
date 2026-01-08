import UIKit

struct OnboardingPageModel {
    let title: String
    let backgroundImageName: String
    let emojis: [String]
}

extension OnboardingPageModel {
    static let pages: [OnboardingPageModel] = [
        OnboardingPageModel(
            title: NSLocalizedString("Track only what you want", comment: "Onboarding page 1"),
            backgroundImageName: "backgr_1",
            emojis: ["🥰", "✨"]
        ),
        OnboardingPageModel(
            title: NSLocalizedString("Even if it's not liters of water and yoga", comment: "Onboarding page 2"),
            backgroundImageName: "backgr_2",
            emojis: ["🔥", "🥳"]
        )
    ]
}


