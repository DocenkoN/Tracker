import UIKit

final class CategoryCell: UITableViewCell {
    
    static let identifier = "CategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(backgroundContainerView)
        backgroundContainerView.addSubview(titleLabel)
        backgroundContainerView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            backgroundContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            backgroundContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            backgroundContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            backgroundContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            backgroundContainerView.heightAnchor.constraint(equalToConstant: 75),
            
            titleLabel.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: backgroundContainerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: backgroundContainerView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with model: CategoryCellModel) {
        titleLabel.text = model.title
        checkmarkImageView.isHidden = !model.isSelected
        
        // Всегда серый фон для каждой категории
        backgroundContainerView.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
    }
}

