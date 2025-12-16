import UIKit

struct OnboardingPageModel {
    let title: String
    let backgroundColor: UIColor
    let emojis: [String]
    let shapes: [String]
}

extension OnboardingPageModel {
    static let pages: [OnboardingPageModel] = [
        OnboardingPageModel(
            title: "Отслеживайте только\nто, что хотите",
            backgroundColor: UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0),
            emojis: ["🥰", "✨"],
            shapes: ["U"]
        ),
        OnboardingPageModel(
            title: "Даже если это\nне литры воды и йога",
            backgroundColor: UIColor(red: 0.99, green: 0.39, blue: 0.61, alpha: 1.0),
            emojis: ["🔥", "🥳"],
            shapes: ["U"]
        )
    ]
}

