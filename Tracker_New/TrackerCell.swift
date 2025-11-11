import UIKit

final class TrackerCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let identifier = "TrackerCell"
    weak var delegate: TrackerCellDelegate?
    private var trackerId: UUID?
    
    // MARK: - UI Elements
    
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let daysLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 17
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(colorView)
        contentView.addSubview(daysLabel)
        contentView.addSubview(plusButton)
        
        colorView.addSubview(emojiLabel)
        colorView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            // Color view (верхняя часть)
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 90),
            
            // Emoji
            emojiLabel.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // Name
            nameLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(equalTo: colorView.bottomAnchor, constant: -12),
            
            // Days label
            daysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            daysLabel.topAnchor.constraint(equalTo: colorView.bottomAnchor, constant: 16),
            
            // Plus button
            plusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            plusButton.centerYAnchor.constraint(equalTo: daysLabel.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 34),
            plusButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with tracker: Tracker, days: Int, isCompleted: Bool, isFutureDate: Bool = false) {
        trackerId = tracker.id
        colorView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        nameLabel.text = tracker.name
        plusButton.backgroundColor = tracker.color
        
        // Форматирование количества дней
        let daysText: String
        if days % 10 == 1 && days % 100 != 11 {
            daysText = "\(days) день"
        } else if (days % 10 >= 2 && days % 10 <= 4) && !(days % 100 >= 12 && days % 100 <= 14) {
            daysText = "\(days) дня"
        } else {
            daysText = "\(days) дней"
        }
        daysLabel.text = daysText
        
        // Отключаем кнопку для будущих дат
        plusButton.isEnabled = !isFutureDate
        
        // Изменение вида кнопки в зависимости от выполнения
        if isCompleted {
            plusButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            plusButton.alpha = 0.3
        } else {
            plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
            plusButton.alpha = isFutureDate ? 0.3 : 1.0
        }
    }
    
    // MARK: - Actions
    
    @objc private func plusButtonTapped() {
        guard let trackerId = trackerId else { return }
        delegate?.didTapPlusButton(for: trackerId)
    }
}

// MARK: - TrackerCellDelegate

protocol TrackerCellDelegate: AnyObject {
    func didTapPlusButton(for trackerId: UUID)
}

