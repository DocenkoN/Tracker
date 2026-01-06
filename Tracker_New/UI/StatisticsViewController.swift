import UIKit

final class StatisticsViewController: UIViewController {
    
    private let trackerStore = TrackerStore()
    private let trackerRecordStore = TrackerRecordStore()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Статистика"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var cardsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var bestPeriodCard = StatisticsCardView()
    private lazy var idealDaysCard = StatisticsCardView()
    private lazy var completedTrackersCard = StatisticsCardView()
    private lazy var averageValueCard = StatisticsCardView()
    
    private lazy var emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Image")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Анализировать пока нечего"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0)
        }
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStatistics()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStatistics()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackerUpdate),
            name: NSNotification.Name("TrackerDidUpdate"),
            object: nil
        )
        trackerRecordStore.delegate = self
    }
    
    @objc private func handleTrackerUpdate() {
        loadStatistics()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        
        cardsStackView.addArrangedSubview(bestPeriodCard)
        cardsStackView.addArrangedSubview(idealDaysCard)
        cardsStackView.addArrangedSubview(completedTrackersCard)
        cardsStackView.addArrangedSubview(averageValueCard)
        
        view.addSubview(titleLabel)
        view.addSubview(cardsStackView)
        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 88),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.widthAnchor.constraint(equalToConstant: 254),
            titleLabel.heightAnchor.constraint(equalToConstant: 41),
            
            cardsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 77),
            cardsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            bestPeriodCard.heightAnchor.constraint(equalToConstant: 90),
            idealDaysCard.heightAnchor.constraint(equalToConstant: 90),
            completedTrackersCard.heightAnchor.constraint(equalToConstant: 90),
            averageValueCard.heightAnchor.constraint(equalToConstant: 90),
            
            emptyStateImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 375),
            emptyStateImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 147),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 463),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyStateLabel.widthAnchor.constraint(equalToConstant: 343),
            emptyStateLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    private func loadStatistics() {
        do {
            let recordsCoreData = try trackerRecordStore.fetchRecords()
            let records = trackerRecordStore.convertToRecords(recordsCoreData)
            
            let trackersCoreData = try trackerStore.fetchTrackers()
            let trackers = trackersCoreData.compactMap { trackerStore.convertToTracker($0) }
            
            let statistics = StatisticsCalculator.calculateStatistics(
                records: records,
                trackers: trackers
            )
            
            updateUI(with: statistics)
        } catch {
            print("Ошибка загрузки статистики: \(error)")
            showEmptyState()
        }
    }
    
    private func updateUI(with statistics: StatisticsData) {
        let hasData = statistics.completedTrackers > 0
        
        cardsStackView.isHidden = !hasData
        emptyStateImageView.isHidden = hasData
        emptyStateLabel.isHidden = hasData
        
        if hasData {
            bestPeriodCard.configure(number: statistics.bestPeriod, description: "Лучший период")
            idealDaysCard.configure(number: statistics.idealDays, description: "Идеальные дни")
            completedTrackersCard.configure(number: statistics.completedTrackers, description: "Трекеров завершено")
            averageValueCard.configure(number: Int(statistics.averageValue.rounded()), description: "Среднее значение")
        }
    }
    
    private func showEmptyState() {
        cardsStackView.isHidden = true
        emptyStateImageView.isHidden = false
        emptyStateLabel.isHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension StatisticsViewController: TrackerRecordStoreDelegate {
    func trackerRecordStoreDidUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.loadStatistics()
        }
    }
}




