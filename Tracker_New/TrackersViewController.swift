import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Properties
    
    var categories: [TrackerCategory] = []
    var completedTrackers: Set<TrackerRecord> = []
    private var visibleCategories: [TrackerCategory] = []
    
    // MARK: - Core Data Stores
    
    private let trackerStore = TrackerStore()
    private let trackerCategoryStore = TrackerCategoryStore()
    private let trackerRecordStore = TrackerRecordStore()
    
    // MARK: - UI Elements
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var currentDate = Date()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        picker.locale = Locale(identifier: "ru_RU")
        return picker
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        label.text = dateFormatter.string(from: currentDate)
        
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Image_star")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStores()
        loadData()
    }
    
    private func setupStores() {
        trackerStore.delegate = self
        trackerCategoryStore.delegate = self
        trackerRecordStore.delegate = self
    }
    
    private func loadData() {
        loadCategories()
        loadCompletedTrackers()
        filterTrackers()
    }
    
    private func loadCategories() {
        do {
            let categoriesCoreData = try trackerCategoryStore.fetchCategories()
            categories = trackerCategoryStore.convertToCategories(categoriesCoreData, trackerStore: trackerStore)
        } catch {
            print("Ошибка загрузки категорий: \(error)")
        }
    }
    
    private func loadCompletedTrackers() {
        do {
            let recordsCoreData = try trackerRecordStore.fetchRecords()
            completedTrackers = trackerRecordStore.convertToRecords(recordsCoreData)
        } catch {
            print("Ошибка загрузки записей: \(error)")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hideDatePickerText()
    }
    
    private func hideDatePickerText() {
        datePicker.subviews.forEach { view in
            view.subviews.forEach { subview in
                if let label = subview as? UILabel {
                    label.textColor = .clear
                }
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(addButton)
        view.addSubview(datePicker)
        view.addSubview(dateLabel) // Label сверху
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            // Add button (42x42 согласно Figma)
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            addButton.widthAnchor.constraint(equalToConstant: 42),
            addButton.heightAnchor.constraint(equalToConstant: 42),
            
            // Date label
            dateLabel.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dateLabel.widthAnchor.constraint(equalToConstant: 77),
            dateLabel.heightAnchor.constraint(equalToConstant: 34),
            
            // Date picker (поверх label, невидимый но кликабельный)
            datePicker.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            datePicker.centerXAnchor.constraint(equalTo: dateLabel.centerXAnchor),
            datePicker.widthAnchor.constraint(equalTo: dateLabel.widthAnchor),
            datePicker.heightAnchor.constraint(equalTo: dateLabel.heightAnchor),
            
            // Title (SF Pro Bold 34, line height 40.8)
            titleLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 1),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Search bar
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            // Collection view
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Empty state image (80x80 согласно Figma)
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Empty state label (SF Pro Medium 12, line height 18)
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        let newHabitVC = NewHabitViewController()
        newHabitVC.delegate = self
        newHabitVC.modalPresentationStyle = .pageSheet
        present(newHabitVC, animated: true)
    }
    
    @objc private func dateChanged() {
        currentDate = datePicker.date
        
        // Обновляем label
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        dateLabel.text = dateFormatter.string(from: currentDate)
        
        // Скрываем системный текст picker после изменения
        DispatchQueue.main.async { [weak self] in
            self?.hideDatePickerText()
        }
        
        filterTrackers()
    }
    
    private func filterTrackers() {
        let calendar = Calendar.current
        let weekDay = calendar.component(.weekday, from: currentDate)
        
        // Конвертируем в наш WeekDay enum (1 = Monday, 7 = Sunday)
        let currentWeekDay: WeekDay
        switch weekDay {
        case 1: currentWeekDay = .sunday
        case 2: currentWeekDay = .monday
        case 3: currentWeekDay = .tuesday
        case 4: currentWeekDay = .wednesday
        case 5: currentWeekDay = .thursday
        case 6: currentWeekDay = .friday
        case 7: currentWeekDay = .saturday
        default: currentWeekDay = .monday
        }
        
        // Фильтруем трекеры по расписанию
        visibleCategories = categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                // Нерегулярные события (без расписания) показываем всегда
                if tracker.schedule.isEmpty {
                    return true
                }
                // Для привычек проверяем расписание
                return tracker.schedule.contains(currentWeekDay)
            }
            
            if filteredTrackers.isEmpty {
                return nil
            }
            
            return TrackerCategory(title: category.title, trackers: filteredTrackers)
        }
        
        collectionView.reloadData()
        
        // Обновляем видимость empty state
        let hasVisibleTrackers = !visibleCategories.isEmpty
        emptyStateImageView.isHidden = hasVisibleTrackers
        emptyStateLabel.isHidden = hasVisibleTrackers
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.identifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        
        // Подсчет количества выполненных дней
        let completedDays = completedTrackers.filter { $0.id == tracker.id }.count
        
        // Проверка, выполнен ли трекер в выбранную дату
        let isCompletedToday = completedTrackers.contains { record in
            record.id == tracker.id && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
        }
        
        // Проверка, является ли выбранная дата будущей
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDate = Calendar.current.startOfDay(for: currentDate)
        let isFutureDate = selectedDate > today
        
        cell.configure(with: tracker, days: completedDays, isCompleted: isCompletedToday, isFutureDate: isFutureDate)
        cell.delegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
        
        header.subviews.forEach { $0.removeFromSuperview() }
        
        // Добавляем заголовок категории
        let label = UILabel()
        label.text = visibleCategories[indexPath.section].title
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 28),
            label.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12)
        ])
        
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - 41) / 2, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
    }
}

// MARK: - NewHabitViewControllerDelegate

extension TrackersViewController: NewHabitViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, category: String) {
        // Сохраняем в Core Data
        do {
            // Создаем или получаем категорию
            let categoryCoreData = try trackerCategoryStore.createCategory(title: category)
            
            // Создаем трекер в Core Data
            _ = try trackerStore.createTracker(from: tracker, category: categoryCoreData)
            
            // Сохраняем контекст
            CoreDataStack.shared.saveContext()
            
            // Обновляем локальные данные
            loadCategories()
            filterTrackers()
        } catch {
            print("Ошибка сохранения трекера: \(error)")
        }
    }
}

// MARK: - TrackerCellDelegate

extension TrackersViewController: TrackerCellDelegate {
    func didTapPlusButton(for trackerId: UUID) {
        // Проверяем, что дата не в будущем
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDate = Calendar.current.startOfDay(for: currentDate)
        
        guard selectedDate <= today else {
            // Нельзя отметить трекер для будущей даты
            return
        }
        
        // Проверяем, существует ли уже запись
        let exists = completedTrackers.contains { record in
            record.id == trackerId && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
        }
        
        do {
            if exists {
                // Удаляем запись из Core Data
                try trackerRecordStore.deleteRecord(trackerId: trackerId, date: currentDate)
                // Удаляем из локального набора
                if let recordToRemove = completedTrackers.first(where: { record in
                    record.id == trackerId && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
                }) {
                    completedTrackers.remove(recordToRemove)
                }
            } else {
                // Создаем запись в Core Data
                _ = try trackerRecordStore.createRecord(trackerId: trackerId, date: currentDate)
                // Добавляем в локальный набор
                let newRecord = TrackerRecord(id: trackerId, date: currentDate)
                completedTrackers.insert(newRecord)
            }
            
            // Сохраняем контекст
            CoreDataStack.shared.saveContext()
            
            // Обновляем коллекцию
            collectionView.reloadData()
        } catch {
            print("Ошибка при работе с записью: \(error)")
        }
    }
}

// MARK: - Store Delegates

extension TrackersViewController: TrackerStoreDelegate {
    func trackerStoreDidUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.loadCategories()
            self?.filterTrackers()
        }
    }
}

extension TrackersViewController: TrackerCategoryStoreDelegate {
    func trackerCategoryStoreDidUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.loadCategories()
            self?.filterTrackers()
        }
    }
}

extension TrackersViewController: TrackerRecordStoreDelegate {
    func trackerRecordStoreDidUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.loadCompletedTrackers()
            self?.collectionView.reloadData()
        }
    }
}


