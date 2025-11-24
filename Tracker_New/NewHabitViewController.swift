import UIKit

protocol NewHabitViewControllerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, category: String)
}

final class NewHabitViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: NewHabitViewControllerDelegate?
    private var selectedCategory: String?
    private var selectedSchedule: [WeekDay] = []
    private var selectedEmojiIndex: Int?
    private var selectedColorIndex: Int?
    var trackerType: TrackerType = .habit // По умолчанию привычка
    
    enum TrackerType {
        case habit // Привычка
        case irregularEvent // Нерегулярное событие
    }
    
    // MARK: - UI Elements
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        textField.layer.cornerRadius = 16
        textField.font = .systemFont(ofSize: 17)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем отступы внутри текстового поля
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private lazy var optionsTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        tableView.layer.cornerRadius = 16
        tableView.isScrollEnabled = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        return collectionView
    }()
    
    private lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.text = "Цвет"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
        return collectionView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var tableViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Data
    
    private let options = ["Категория", "Расписание"]
    
    private let emojis = ["😊", "😻", "🌺", "🐶", "😇", "😠", "🥶", "🤔", "🥦", "🏓", "🥇", "🎸", "🙌", "🍔", "🏝️", "😴", "❤️", "😮"]
    
    private let colors: [UIColor] = [
        UIColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0), // Красный
        UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0), // Оранжевый
        UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0), // Синий
        UIColor(red: 0.556, green: 0.266, blue: 0.678, alpha: 1.0), // Фиолетовый
        UIColor(red: 0.992, green: 0.227, blue: 0.412, alpha: 1.0), // Розовый
        UIColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1.0), // Зеленый
        UIColor(red: 0.0, green: 0.690, blue: 0.459, alpha: 1.0), // Мятный
        UIColor(red: 0.0, green: 0.478, blue: 0.988, alpha: 1.0), // Темно-синий
        UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0), // Персиковый
        UIColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 1.0), // Лавандовый
        UIColor(red: 0.686, green: 0.322, blue: 0.871, alpha: 1.0), // Яркий фиолетовый
        UIColor(red: 0.4, green: 0.9, blue: 0.5, alpha: 1.0), // Светло-зеленый
        UIColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 1.0), // Сине-фиолетовый
        UIColor(red: 1.0, green: 0.388, blue: 0.278, alpha: 1.0), // Коралловый
        UIColor(red: 0.9, green: 0.4, blue: 0.6, alpha: 1.0), // Розово-красный
        UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0), // Голубой
        UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0), // Коричневый
        UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0) // Светло-зеленый
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        updateTableViewHeight()
    }
    
    // MARK: - Validation
    
    private func updateCreateButtonState() {
        let isNameValid = !(nameTextField.text?.isEmpty ?? true)
        let isCategorySelected = selectedCategory != nil
        let isScheduleSelected = trackerType == .irregularEvent || !selectedSchedule.isEmpty
        let isEmojiSelected = selectedEmojiIndex != nil
        let isColorSelected = selectedColorIndex != nil
        
        let isValid = isNameValid && isCategorySelected && isScheduleSelected && isEmojiSelected && isColorSelected
        
        createButton.isEnabled = isValid
        createButton.backgroundColor = isValid ? UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0) : .systemGray
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(optionsTableView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiCollectionView)
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorCollectionView)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Name text field
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            // Options table view
            optionsTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            optionsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        tableViewHeightConstraint = optionsTableView.heightAnchor.constraint(equalToConstant: 150)
        tableViewHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            
            // Emoji label
            emojiLabel.topAnchor.constraint(equalTo: optionsTableView.bottomAnchor, constant: 32),
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Emoji collection view
            emojiCollectionView.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 24),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: 156),
            
            // Color label
            colorLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 40),
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Color collection view
            colorCollectionView.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 24),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            colorCollectionView.heightAnchor.constraint(equalToConstant: 156),
            colorCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Cancel button
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -4),
            
            // Create button
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 4)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty,
              let category = selectedCategory,
              let emojiIndex = selectedEmojiIndex,
              let colorIndex = selectedColorIndex else {
            return
        }
        
        // Для нерегулярного события расписание пустое, для привычки - выбранное
        let schedule = trackerType == .irregularEvent ? [] : selectedSchedule
        
        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: colors[colorIndex],
            emoji: emojis[emojiIndex],
            schedule: schedule
        )
        
        delegate?.didCreateTracker(newTracker, category: category)
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange() {
        updateCreateButtonState()
    }
    
    // MARK: - Public Methods
    
    func setCategory(_ category: String) {
        selectedCategory = category
        updateCreateButtonState()
        optionsTableView.reloadData()
    }
    
    func setSchedule(_ schedule: [WeekDay]) {
        selectedSchedule = schedule
        updateCreateButtonState()
        updateTableViewHeight()
        optionsTableView.reloadData()
    }
    
    private func updateTableViewHeight() {
        let height = trackerType == .habit ? 150 : 75
        tableViewHeightConstraint?.constant = CGFloat(height)
    }
}

// MARK: - UITableViewDataSource

extension NewHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Для нерегулярного события показываем только категорию
        return trackerType == .habit ? options.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "OptionCell")
        
        cell.textLabel?.text = options[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        // Показываем выбранные значения
        if indexPath.row == 0 {
            cell.detailTextLabel?.text = selectedCategory
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.font = .systemFont(ofSize: 14)
        } else if indexPath.row == 1 {
            if !selectedSchedule.isEmpty {
                cell.detailTextLabel?.text = formatSchedule(selectedSchedule)
                cell.detailTextLabel?.textColor = .gray
                cell.detailTextLabel?.font = .systemFont(ofSize: 14)
            }
        }
        
        return cell
    }
    
    private func formatSchedule(_ schedule: [WeekDay]) -> String {
        if schedule.count == 7 {
            return "Каждый день"
        }
        let weekDayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        return schedule.sorted(by: { $0.rawValue < $1.rawValue })
            .map { weekDayNames[$0.rawValue - 1] }
            .joined(separator: ", ")
    }
}

// MARK: - UITableViewDelegate

extension NewHabitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            // Категория - пока заглушка
            setCategory("Важное")
        } else if indexPath.row == 1 && trackerType == .habit {
            // Открываем экран расписания только для привычек
            let scheduleVC = ScheduleViewController()
            scheduleVC.delegate = self
            scheduleVC.setSelectedDays(selectedSchedule)
            scheduleVC.modalPresentationStyle = .pageSheet
            present(scheduleVC, animated: true)
        }
    }
}

// MARK: - ScheduleViewControllerDelegate

extension NewHabitViewController: ScheduleViewControllerDelegate {
    func didSelectSchedule(_ schedule: [WeekDay]) {
        setSchedule(schedule)
    }
}

// MARK: - UICollectionViewDataSource

extension NewHabitViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollectionView {
            return emojis.count
        } else if collectionView == colorCollectionView {
            return colors.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
            let emoji = emojis[indexPath.item]
            let isSelected = selectedEmojiIndex == indexPath.item
            cell.configure(with: emoji, isSelected: isSelected)
            return cell
        } else if collectionView == colorCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCell
            let color = colors[indexPath.item]
            let isSelected = selectedColorIndex == indexPath.item
            cell.configure(with: color, isSelected: isSelected)
            return cell
        }
        return UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegate

extension NewHabitViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            selectedEmojiIndex = indexPath.item
            emojiCollectionView.reloadData()
            updateCreateButtonState()
        } else if collectionView == colorCollectionView {
            selectedColorIndex = indexPath.item
            colorCollectionView.reloadData()
            updateCreateButtonState()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NewHabitViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - EmojiCell

final class EmojiCell: UICollectionViewCell {
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        if isSelected {
            contentView.backgroundColor = UIColor(white: 0.9, alpha: 1.0) // Серый фон
            contentView.layer.cornerRadius = 16
            contentView.layer.borderWidth = 0
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.cornerRadius = 0
            contentView.layer.borderWidth = 0
        }
    }
}

// MARK: - ColorCell

final class ColorCell: UICollectionViewCell {
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(colorView)
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -6),
            colorView.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: -6)
        ])
    }
    
    func configure(with color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 8
        
        if isSelected {
            // Внутренняя тонкая белая линия
            colorView.layer.borderWidth = 3
            colorView.layer.borderColor = UIColor.white.cgColor
            
            // Внешняя цветная граница с прозрачностью 30%
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
            contentView.layer.cornerRadius = 8
            contentView.layer.shadowColor = color.cgColor
            contentView.layer.shadowRadius = 4
            contentView.layer.shadowOpacity = 0.3
            contentView.layer.shadowOffset = .zero
        } else {
            colorView.layer.borderWidth = 0
            contentView.layer.borderWidth = 0
            contentView.layer.cornerRadius = 0
            contentView.layer.shadowOpacity = 0
        }
    }
}

