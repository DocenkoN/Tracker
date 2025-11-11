import UIKit

protocol NewHabitViewControllerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, category: String)
}

final class NewHabitViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: NewHabitViewControllerDelegate?
    private var selectedCategory: String?
    private var selectedSchedule: [WeekDay] = []
    
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
    
    // MARK: - Data
    
    private let options = ["Категория", "Расписание"]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    // MARK: - Validation
    
    private func updateCreateButtonState() {
        let isNameValid = !(nameTextField.text?.isEmpty ?? true)
        let isCategorySelected = selectedCategory != nil
        let isScheduleSelected = !selectedSchedule.isEmpty
        
        let isValid = isNameValid && isCategorySelected && isScheduleSelected
        
        createButton.isEnabled = isValid
        createButton.backgroundColor = isValid ? UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0) : .systemGray
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(titleLabel)
        view.addSubview(nameTextField)
        view.addSubview(optionsTableView)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Name text field
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            // Options table view
            optionsTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            optionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            optionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            optionsTableView.heightAnchor.constraint(equalToConstant: 150),
            
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
              !selectedSchedule.isEmpty else {
            return
        }
        
        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: UIColor(red: 51/255, green: 207/255, blue: 105/255, alpha: 1.0), // rgba(51, 207, 105, 1)
            emoji: "🎯",
            schedule: selectedSchedule
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
        optionsTableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension NewHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
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
            setCategory("Важное")
        } else if indexPath.row == 1 {
            // Открываем экран расписания
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

