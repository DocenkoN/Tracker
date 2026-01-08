import UIKit
import YandexMobileMetrica

final class TrackersViewController: UIViewController {
    
    var categories: [TrackerCategory] = []
    var completedTrackers: Set<TrackerRecord> = []
    private var visibleCategories: [TrackerCategory] = []
    private var searchText: String = ""
    private var currentFilter: TrackerFilter?
    
    private let trackerStore = TrackerStore()
    private let trackerCategoryStore = TrackerCategoryStore()
    private let trackerRecordStore = TrackerRecordStore()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
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
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.textAlignment = .center
        label.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1.0) :
                UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        }
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
        label.text = NSLocalizedString("Trackers", comment: "Main screen title")
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchTextField: UISearchTextField = {
        let textField = UISearchTextField()
        textField.placeholder = NSLocalizedString("Search", comment: "Search placeholder")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        return textField
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true
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
        label.text = NSLocalizedString("What will we track?", comment: "Empty state label")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nothingFoundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "monocle")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var nothingFoundLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Nothing found", comment: "Nothing found label")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var filtersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Filters", comment: "Filters button"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filtersButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStores()
        loadData()
        setupCollectionViewInsets()
    }
    
    private func setupCollectionViewInsets() {
        // Добавляем contentInset снизу, чтобы ячейки могли прокручиваться выше кнопки "Фильтры"
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 82, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 82, right: 0)
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
    
    private func isCompleted(id: UUID, date: Date) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        return completedTrackers.contains { record in
            record.trackerId == id && calendar.isDate(record.date, inSameDayAs: normalizedDate)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hideDatePickerText()
        
        // Аналитика: открытие экрана
        let parameters: [String: Any] = [
            "event": "open",
            "screen": "Main"
        ]
        YMMYandexMetrica.reportEvent("open", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: open, screen: Main")
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Аналитика: закрытие экрана
        let parameters: [String: Any] = [
            "event": "close",
            "screen": "Main"
        ]
        YMMYandexMetrica.reportEvent("close", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: close, screen: Main")
        #endif
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
    
    private func setupUI() {
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        
        view.addSubview(addButton)
        view.addSubview(datePicker)
        view.addSubview(dateLabel)
        view.addSubview(titleLabel)
        view.addSubview(searchTextField)
        view.addSubview(collectionView)
        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)
        view.addSubview(nothingFoundImageView)
        view.addSubview(nothingFoundLabel)
        view.addSubview(filtersButton)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            addButton.widthAnchor.constraint(equalToConstant: 42),
            addButton.heightAnchor.constraint(equalToConstant: 42),
            
            dateLabel.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dateLabel.widthAnchor.constraint(equalToConstant: 77),
            dateLabel.heightAnchor.constraint(equalToConstant: 34),
            
            datePicker.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            datePicker.centerXAnchor.constraint(equalTo: dateLabel.centerXAnchor),
            datePicker.widthAnchor.constraint(equalTo: dateLabel.widthAnchor),
            datePicker.heightAnchor.constraint(equalTo: dateLabel.heightAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 1),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchTextField.heightAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: filtersButton.topAnchor, constant: -16),
            
            filtersButton.widthAnchor.constraint(equalToConstant: 114),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nothingFoundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nothingFoundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nothingFoundImageView.widthAnchor.constraint(equalToConstant: 80),
            nothingFoundImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nothingFoundLabel.topAnchor.constraint(equalTo: nothingFoundImageView.bottomAnchor, constant: 8),
            nothingFoundLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func addButtonTapped() {
        // Аналитика: тап на кнопке добавления трека
        let parameters: [String: Any] = [
            "event": "click",
            "screen": "Main",
            "item": "add_track"
        ]
        YMMYandexMetrica.reportEvent("click", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: click, screen: Main, item: add_track")
        #endif
        
        let newHabitVC = NewHabitViewController()
        newHabitVC.delegate = self
        newHabitVC.modalPresentationStyle = .pageSheet
        present(newHabitVC, animated: true)
    }
    
    @objc private func filtersButtonTapped() {
        // Аналитика: тап на кнопке фильтра
        let parameters: [String: Any] = [
            "event": "click",
            "screen": "Main",
            "item": "filter"
        ]
        YMMYandexMetrica.reportEvent("click", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: click, screen: Main, item: filter")
        #endif
        
        let filtersVC = FiltersViewController()
        filtersVC.currentFilter = currentFilter
        filtersVC.delegate = self
        filtersVC.modalPresentationStyle = .pageSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = filtersVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.preferredCornerRadius = 16
                sheet.prefersGrabberVisible = false
            }
        }
        
        present(filtersVC, animated: true)
    }
    
    @objc private func dateChanged() {
        currentDate = datePicker.date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        dateLabel.text = dateFormatter.string(from: currentDate)
        
        DispatchQueue.main.async { [weak self] in
            self?.hideDatePickerText()
        }
        
        filterTrackers()
    }
    
    private func filterTrackers() {
        let calendar = Calendar.current
        let weekDay = calendar.component(.weekday, from: currentDate)
        
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
        
        // Сначала фильтруем по дню недели и поиску
        var filteredByScheduleAndSearch: [TrackerCategory] = categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                // Фильтрация по дню недели
                let matchesSchedule: Bool
                if tracker.schedule.isEmpty {
                    matchesSchedule = true
                } else {
                    matchesSchedule = tracker.schedule.contains(currentWeekDay)
                }
                
                // Фильтрация по тексту поиска
                let matchesSearch: Bool
                if searchText.isEmpty {
                    matchesSearch = true
                } else {
                    matchesSearch = tracker.name.lowercased().contains(searchText.lowercased())
                }
                
                return matchesSchedule && matchesSearch
            }
            
            if filteredTrackers.isEmpty {
                return nil
            }
            
            return TrackerCategory(title: category.title, trackers: filteredTrackers)
        }
        
        // Применяем дополнительный фильтр, если он выбран
        if let filter = currentFilter {
            filteredByScheduleAndSearch = filteredByScheduleAndSearch.compactMap { category in
                let filteredTrackers = category.trackers.filter { tracker in
                    switch filter {
                    case .all:
                        return true
                    case .today:
                        // "Трекеры на сегодня" - это сброс фильтрации, показываем все трекеры на выбранный день
                        // Фильтрация по расписанию уже применена выше
                        return true
                    case .completed:
                        // Завершенные трекеры на выбранную дату
                        return isCompleted(id: tracker.id, date: currentDate)
                    case .notCompleted:
                        // Не завершенные трекеры на выбранную дату
                        return !isCompleted(id: tracker.id, date: currentDate)
                    }
                }
                
                if filteredTrackers.isEmpty {
                    return nil
                }
                
                return TrackerCategory(title: category.title, trackers: filteredTrackers)
            }
        }
        
        visibleCategories = filteredByScheduleAndSearch
        
        collectionView.reloadData()
        
        // Определяем, есть ли трекеры на выбранный день (без учета фильтра)
        let hasTrackersForSelectedDate = !categories.compactMap { category in
            let trackersForDate = category.trackers.filter { tracker in
                if tracker.schedule.isEmpty {
                    return true
                } else {
                    return tracker.schedule.contains(currentWeekDay)
                }
            }
            return trackersForDate.isEmpty ? nil : category
        }.isEmpty
        
        // Обновляем состояние пустого экрана
        let hasVisibleTrackers = !visibleCategories.isEmpty
        let hasActiveFilter = currentFilter != nil && currentFilter != .all && currentFilter != .today
        let hasActiveSearch = !searchText.isEmpty
        let showNothingFound = (hasActiveFilter || hasActiveSearch) && !hasVisibleTrackers
        
        if showNothingFound {
            // Показываем "Ничего не найдено" если применен фильтр или поиск и ничего не найдено
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
            nothingFoundImageView.isHidden = false
            nothingFoundLabel.isHidden = false
            collectionView.isHidden = true
            // Скрываем кнопку фильтров при показе "Ничего не найдено"
            filtersButton.isHidden = true
        } else if !hasVisibleTrackers {
            // Показываем стандартную заглушку если нет трекеров вообще
            emptyStateImageView.isHidden = false
            emptyStateLabel.isHidden = false
            nothingFoundImageView.isHidden = true
            nothingFoundLabel.isHidden = true
            collectionView.isHidden = true
            // Скрываем кнопку фильтров, если нет трекеров на выбранный день
            filtersButton.isHidden = !hasTrackersForSelectedDate
        } else {
            // Есть трекеры для отображения
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
            nothingFoundImageView.isHidden = true
            nothingFoundLabel.isHidden = true
            collectionView.isHidden = false
            // Показываем кнопку фильтров, если есть трекеры на выбранный день
            filtersButton.isHidden = !hasTrackersForSelectedDate
        }
    }
    
    @objc private func searchTextChanged() {
        searchText = searchTextField.text ?? ""
        filterTrackers()
    }
}

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
        
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: currentDate)
        
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        let isCompletedToday = completedTrackers.contains { record in
            record.trackerId == tracker.id && calendar.isDate(record.date, inSameDayAs: normalizedDate)
        }
        
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
        
        let label = UILabel()
        label.text = visibleCategories[indexPath.section].title
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 28),
            label.topAnchor.constraint(equalTo: header.bottomAnchor, constant: -20)
        ])
        
        return header
    }
}

extension TrackersViewController {
    private func editTracker(_ tracker: Tracker) {
        // Аналитика: выбор редактирования в контекстном меню
        let parameters: [String: Any] = [
            "event": "click",
            "screen": "Main",
            "item": "edit"
        ]
        YMMYandexMetrica.reportEvent("click", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: click, screen: Main, item: edit")
        #endif
        
        // Находим категорию трекера
        var categoryTitle = ""
        for category in categories {
            if category.trackers.contains(where: { $0.id == tracker.id }) {
                categoryTitle = category.title
                break
            }
        }
        
        // Подсчитываем количество завершенных дней
        let completedDaysCount = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        // Создаем экран редактирования
        let newHabitVC = NewHabitViewController()
        newHabitVC.configureForEditing(tracker: tracker, categoryTitle: categoryTitle, completedDaysCount: completedDaysCount)
        
        newHabitVC.onCreateTracker = { [weak self] updatedTracker, categoryTitle in
            self?.updateTracker(updatedTracker, categoryTitle: categoryTitle)
        }
        
        let navController = UINavigationController(rootViewController: newHabitVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    private func confirmDeleteTracker(_ tracker: Tracker) {
        // Аналитика: выбор удаления в контекстном меню
        let parameters: [String: Any] = [
            "event": "click",
            "screen": "Main",
            "item": "delete"
        ]
        YMMYandexMetrica.reportEvent("click", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: click, screen: Main, item: delete")
        #endif
        
        // Показываем подтверждение удаления
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("Are you sure you want to delete tracker?", comment: "Delete confirmation"),
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete action"), style: .destructive) { [weak self] _ in
            self?.performDeleteTracker(tracker)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel action"), style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // Для iPad нужно указать sourceView
        if let popover = alert.popoverPresentationController {
            // Ищем ячейку по tracker ID
            var foundCell: UICollectionViewCell?
            for section in 0..<visibleCategories.count {
                for item in 0..<visibleCategories[section].trackers.count {
                    if visibleCategories[section].trackers[item].id == tracker.id {
                        let indexPath = IndexPath(item: item, section: section)
                        foundCell = collectionView.cellForItem(at: indexPath)
                        break
                    }
                }
                if foundCell != nil { break }
            }
            
            if let cell = foundCell {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            } else {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func performDeleteTracker(_ tracker: Tracker) {
        do {
            // Удаляем все записи трекера
            try trackerRecordStore.deleteRecords(for: tracker.id)
            
            // Удаляем трекер из CoreData
            if let trackerCoreData = try trackerStore.fetchTracker(by: tracker.id) {
                try trackerStore.deleteTracker(trackerCoreData)
            }
            
            CoreDataStack.shared.saveContext()
            
            // Обновляем данные и UI
            loadCategories()
            loadCompletedTrackers()
            filterTrackers()
        } catch {
            print("Ошибка удаления трекера: \(error)")
            
            // Показываем ошибку пользователю
            let errorMessage = String(format: NSLocalizedString("Failed to delete tracker", comment: "Delete error"), error.localizedDescription)
            let errorAlert = UIAlertController(
                title: NSLocalizedString("Error", comment: "Error title"),
                message: errorMessage,
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default))
            present(errorAlert, animated: true)
        }
    }
}

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - 41) / 2, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 38)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 8, right: 16)
    }
}

extension TrackersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.section < visibleCategories.count,
              indexPath.item < visibleCategories[indexPath.section].trackers.count else {
            return nil
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { [weak self] _ in
            let editAction = UIAction(
                title: NSLocalizedString("Edit", comment: "Edit tracker")
            ) { _ in
                self?.editTracker(tracker)
            }
            
            let deleteAction = UIAction(
                title: NSLocalizedString("Delete", comment: "Delete tracker"),
                attributes: .destructive
            ) { _ in
                self?.confirmDeleteTracker(tracker)
            }
            
            return UIMenu(children: [editAction, deleteAction])
        }
    }
}

extension TrackersViewController: NewHabitViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, category: String) {
        do {
            let categoryCoreData = try trackerCategoryStore.createCategory(title: category)
            
            _ = try trackerStore.createTracker(from: tracker, category: categoryCoreData)
            
            CoreDataStack.shared.saveContext()
            
            loadCategories()
            filterTrackers()
        } catch {
            print("Ошибка сохранения трекера: \(error)")
        }
    }
    
    private func updateTracker(_ tracker: Tracker, categoryTitle: String) {
        do {
            guard let trackerCoreData = try trackerStore.fetchTracker(by: tracker.id) else {
                return
            }
            
            // Получаем hex цвет
            guard let colorHex = tracker.color.toHex() else {
                return
            }
            
            // Находим или создаем категорию
            var categoryCoreData = try trackerCategoryStore.fetchCategory(by: categoryTitle)
            if categoryCoreData == nil {
                categoryCoreData = try trackerCategoryStore.createCategory(title: categoryTitle)
            }
            
            guard let categoryCoreData = categoryCoreData else {
                return
            }
            
            // Обновляем данные трекера
            trackerCoreData.name = tracker.name
            trackerCoreData.emoji = tracker.emoji
            trackerCoreData.color = colorHex
            trackerCoreData.schedule = tracker.schedule.map { String($0.rawValue) }.joined(separator: ",")
            trackerCoreData.category = categoryCoreData
            
            try trackerStore.updateTracker(trackerCoreData, with: tracker)
            CoreDataStack.shared.saveContext()
            
            loadCategories()
            filterTrackers()
        } catch {
            print("Ошибка обновления трекера: \(error)")
        }
    }
}

extension TrackersViewController: TrackerCellDelegate {
    func didTapPlusButton(for trackerId: UUID) {
        // Аналитика: тап на кнопке о выполнении трека
        let parameters: [String: Any] = [
            "event": "click",
            "screen": "Main",
            "item": "track"
        ]
        YMMYandexMetrica.reportEvent("click", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: click, screen: Main, item: track")
        #endif
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let normalizedDate = calendar.startOfDay(for: currentDate)
        
        guard normalizedDate <= today else {
            return
        }
        
        // Проверяем через isCompleted метод (как в референсе)
        let isCompleted = isCompleted(id: trackerId, date: currentDate)
        
        do {
            if isCompleted {
                try trackerRecordStore.deleteRecord(trackerId: trackerId, date: normalizedDate)
                
                // Удаляем из Set в памяти (как в референсе)
                if let recordToRemove = completedTrackers.first(where: { existingRecord in
                    existingRecord.trackerId == trackerId && calendar.isDate(existingRecord.date, inSameDayAs: normalizedDate)
                }) {
                    completedTrackers.remove(recordToRemove)
                }
            } else {
                try trackerRecordStore.addRecord(trackerId: trackerId, date: normalizedDate)
                // Добавляем в Set в памяти (как в референсе)
                let record = TrackerRecord(trackerId: trackerId, date: normalizedDate)
                completedTrackers.insert(record)
            }
            
            // Обновляем только конкретную ячейку (как в референсе)
            // Ищем indexPath по trackerId в visibleCategories
            var foundIndexPath: IndexPath?
            for section in 0..<visibleCategories.count {
                for row in 0..<visibleCategories[section].trackers.count {
                    if visibleCategories[section].trackers[row].id == trackerId {
                        foundIndexPath = IndexPath(row: row, section: section)
                        break
                    }
                }
                if foundIndexPath != nil { break }
            }
            
            if let indexPath = foundIndexPath {
                collectionView.reloadItems(at: [indexPath])
            } else {
                collectionView.reloadData()
            }
        } catch {
            print("Ошибка при работе с записью: \(error)")
            // Перезагружаем данные из CoreData в случае ошибки
            loadCompletedTrackers()
            collectionView.reloadData()
        }
    }
}

extension TrackersViewController: TrackerStoreDelegate {
    func trackerStoreDidUpdate() {
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

extension TrackersViewController: FiltersViewControllerDelegate {
    func didSelectFilter(_ filter: TrackerFilter) {
        // Если выбран "Трекеры на сегодня", устанавливаем текущую дату
        if filter == .today {
            currentDate = Date()
            datePicker.date = currentDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy"
            dateLabel.text = dateFormatter.string(from: currentDate)
            
            DispatchQueue.main.async { [weak self] in
                self?.hideDatePickerText()
            }
        }
        
        // Устанавливаем выбранный фильтр для всех случаев
        currentFilter = filter
        filterTrackers()
    }
}

extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


