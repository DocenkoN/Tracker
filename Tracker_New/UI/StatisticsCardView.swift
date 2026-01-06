import UIKit

final class StatisticsCardView: UIView {
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0) : .white
        }
        layer.cornerRadius = 16
        clipsToBounds = true
        
        addSubview(numberLabel)
        addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            numberLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 7),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupGradientBorder()
    }
    
    private func setupGradientBorder() {
        // Удаляем старый градиент, если есть
        layer.sublayers?.forEach { if $0 is CAGradientLayer { $0.removeFromSuperlayer() } }
        
        // Создаем градиентную границу через отдельный слой
        let borderLayer = CAGradientLayer()
        borderLayer.frame = bounds
        borderLayer.colors = [
            UIColor(red: 0/255, green: 123/255, blue: 250/255, alpha: 1.0).cgColor,
            UIColor(red: 70/255, green: 230/255, blue: 157/255, alpha: 1.0).cgColor,
            UIColor(red: 253/255, green: 76/255, blue: 73/255, alpha: 1.0).cgColor
        ]
        borderLayer.startPoint = CGPoint(x: 0, y: 0)
        borderLayer.endPoint = CGPoint(x: 1, y: 1)
        borderLayer.cornerRadius = 16
        
        // Создаем маску для границы (только граница, не заливка)
        let maskLayer = CAShapeLayer()
        let outerPath = UIBezierPath(roundedRect: bounds, cornerRadius: 16)
        let innerPath = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 15)
        outerPath.append(innerPath.reversing())
        maskLayer.path = outerPath.cgPath
        maskLayer.fillRule = .evenOdd
        borderLayer.mask = maskLayer
        
        layer.insertSublayer(borderLayer, at: 0)
    }
    
    func configure(number: Int, description: String) {
        numberLabel.text = "\(number)"
        descriptionLabel.text = description
    }
}

