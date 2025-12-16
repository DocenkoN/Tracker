import UIKit

final class OnboardingContentViewController: UIViewController {
    
    private let pageModel: OnboardingPageModel
    
    private lazy var backgroundGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        let topColor = pageModel.backgroundColor
        let bottomColor = pageModel.backgroundColor.withAlphaComponent(0.7)
        gradient.colors = [topColor.cgColor, bottomColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        return gradient
    }()
    
    private lazy var backgroundPatternView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = pageModel.title
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(pageModel: OnboardingPageModel) {
        self.pageModel = pageModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        setupBackgroundPattern()
    }
    
    private func setupUI() {
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        
        view.addSubview(backgroundPatternView)
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            backgroundPatternView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundPatternView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundPatternView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundPatternView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupBackgroundPattern() {
        backgroundPatternView.subviews.forEach { $0.removeFromSuperview() }
        
        let spacing: CGFloat = 90
        let emojiSize: CGFloat = 50
        let viewWidth = view.bounds.width
        let viewHeight = view.bounds.height
        
        let rows = Int(viewHeight / spacing) + 3
        let cols = Int(viewWidth / spacing) + 3
        
        for row in 0..<rows {
            for col in 0..<cols {
                let baseX = CGFloat(col) * spacing - spacing * 0.3
                let baseY = CGFloat(row) * spacing - spacing * 0.3
                
                if pageModel.emojis.contains("🥰") {
                    let emojiLabel = UILabel()
                    emojiLabel.text = "🥰"
                    emojiLabel.font = .systemFont(ofSize: emojiSize)
                    emojiLabel.frame = CGRect(x: baseX, y: baseY, width: emojiSize, height: emojiSize)
                    backgroundPatternView.addSubview(emojiLabel)
                }
                
                if pageModel.emojis.contains("✨") {
                    if (row + col) % 3 == 0 {
                        let sparkleLabel = UILabel()
                        sparkleLabel.text = "✨"
                        sparkleLabel.font = .systemFont(ofSize: emojiSize * 0.6)
                        sparkleLabel.frame = CGRect(x: baseX + 30, y: baseY + 20, width: emojiSize * 0.6, height: emojiSize * 0.6)
                        backgroundPatternView.addSubview(sparkleLabel)
                    }
                }
                
                if pageModel.emojis.contains("🔥") {
                    let fireLabel = UILabel()
                    fireLabel.text = "🔥"
                    fireLabel.font = .systemFont(ofSize: emojiSize)
                    fireLabel.frame = CGRect(x: baseX, y: baseY, width: emojiSize, height: emojiSize)
                    backgroundPatternView.addSubview(fireLabel)
                }
                
                if pageModel.emojis.contains("🥳") {
                    if (row + col) % 2 == 1 {
                        let partyLabel = UILabel()
                        partyLabel.text = "🥳"
                        partyLabel.font = .systemFont(ofSize: emojiSize)
                        partyLabel.frame = CGRect(x: baseX + 25, y: baseY + 25, width: emojiSize, height: emojiSize)
                        backgroundPatternView.addSubview(partyLabel)
                    }
                }
                
                if (row + col) % 4 == 0 {
                    let shapeView = UIView()
                    shapeView.backgroundColor = .clear
                    shapeView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
                    shapeView.layer.borderWidth = 2.5
                    shapeView.frame = CGRect(x: baseX + 20, y: baseY + 15, width: 35, height: 35)
                    shapeView.layer.cornerRadius = 6
                    backgroundPatternView.addSubview(shapeView)
                }
            }
        }
    }
}

