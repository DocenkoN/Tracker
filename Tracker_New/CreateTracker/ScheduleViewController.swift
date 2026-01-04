import UIKit

protocol ScheduleViewControllerDelegate: AnyObject {
    func didSelectSchedule(_ schedule: [WeekDay])
}

final class ScheduleViewController: UIViewController {
    
    weak var delegate: ScheduleViewControllerDelegate?
    private var selectedDays: Set<WeekDay> = []
    
    private let weekDays: [(day: WeekDay, name: String)] = [
        (.monday, "Понедельник"),
        (.tuesday, "Вторник"),
        (.wednesday, "Среда"),
        (.thursday, "Четверг"),
        (.friday, "Пятница"),
        (.saturday, "Суббота"),
        (.sunday, "Воскресенье")
    ]
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Расписание"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DayCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(white: 0.82, alpha: 1.0)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .black
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 525),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func setSelectedDays(_ days: [WeekDay]) {
        selectedDays = Set(days)
        tableView.reloadData()
    }
    
    @objc private func doneButtonTapped() {
        let schedule = Array(selectedDays).sorted(by: { $0.rawValue < $1.rawValue })
        delegate?.didSelectSchedule(schedule)
        dismiss(animated: true)
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        let day = weekDays[sender.tag].day
        
        if sender.isOn {
            selectedDays.insert(day)
        } else {
            selectedDays.remove(day)
        }
    }
}

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weekDays.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell", for: indexPath)
        let weekDay = weekDays[indexPath.row]
        
        cell.textLabel?.text = weekDay.name
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        // Скрываем разделитель для последней ячейки
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        let switchControl = UISwitch()
        switchControl.isOn = selectedDays.contains(weekDay.day)
        switchControl.onTintColor = UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0)
        switchControl.tag = indexPath.row
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        
        cell.accessoryView = switchControl
        
        return cell
    }
}

extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}


