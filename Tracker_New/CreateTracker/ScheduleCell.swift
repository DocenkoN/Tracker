import UIKit

final class ScheduleCell: UITableViewCell {
    
    // MARK: - Properties
    var onSwitchChanged: ((Bool) -> Void)?
    
    // MARK: - UI elements
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0) : 
                UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        }
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var daySwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(white: 0.33, alpha: 1.0) : 
                UIColor(white: 0.82, alpha: 1.0)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - Private methods
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(daySwitch)
        containerView.addSubview(separatorView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 75),
            
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            daySwitch.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            daySwitch.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            daySwitch.widthAnchor.constraint(equalToConstant: 51),
            daySwitch.heightAnchor.constraint(equalToConstant: 31),
            
            separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    private func setupActions() {
        daySwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }
    
    // MARK: - Public methods
    func configure(dayName: String, isSelected: Bool, isFirst: Bool, isLast: Bool) {
        titleLabel.text = dayName
        daySwitch.isOn = isSelected
        containerView.layer.cornerRadius = 0
        
        if isFirst && isLast {
            containerView.layer.cornerRadius = 16
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            containerView.layer.cornerRadius = 16
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            containerView.layer.cornerRadius = 16
            containerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        separatorView.isHidden = isLast
    }
    
    // MARK: - Actions
    @objc private func switchChanged() {
        onSwitchChanged?(daySwitch.isOn)
    }
}

