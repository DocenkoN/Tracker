import UIKit

protocol ScheduleViewControllerDelegate: AnyObject {
    func didSelectSchedule(_ schedule: [WeekDay])
}

final class ScheduleViewController: UIViewController {
    
    weak var delegate: ScheduleViewControllerDelegate?
    private var selectedDays: Set<WeekDay> = []
    
    private let weekDays: [(day: WeekDay, name: String)] = [
        (.monday, NSLocalizedString("Monday", comment: "Monday")),
        (.tuesday, NSLocalizedString("Tuesday", comment: "Tuesday")),
        (.wednesday, NSLocalizedString("Wednesday", comment: "Wednesday")),
        (.thursday, NSLocalizedString("Thursday", comment: "Thursday")),
        (.friday, NSLocalizedString("Friday", comment: "Friday")),
        (.saturday, NSLocalizedString("Saturday", comment: "Saturday")),
        (.sunday, NSLocalizedString("Sunday", comment: "Sunday"))
    ]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: "ScheduleCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        tableView.separatorStyle = .none
        tableView.rowHeight = 75
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Done", comment: "Done button"), for: .normal)
        button.setTitleColor(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
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
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        
        navigationItem.title = NSLocalizedString("Schedule", comment: "Schedule screen title")
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .white : .black
            },
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        navigationItem.hidesBackButton = true
        
        view.addSubview(tableView)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -16),
            
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
    
}

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weekDays.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath) as? ScheduleCell else {
            return UITableViewCell()
        }
        
        let weekDay = weekDays[indexPath.row]
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == weekDays.count - 1
        
        cell.configure(
            dayName: weekDay.name,
            isSelected: selectedDays.contains(weekDay.day),
            isFirst: isFirst,
            isLast: isLast
        )
        
        cell.onSwitchChanged = { [weak self] isOn in
            if isOn {
                self?.selectedDays.insert(weekDay.day)
            } else {
                self?.selectedDays.remove(weekDay.day)
            }
        }
        
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


