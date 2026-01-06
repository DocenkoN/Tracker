import UIKit

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
        label.text = "Трекеры"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchTextField: UISearchTextField = {
        let textField = UISearchTextField()
        textField.placeholder = "Поиск"
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
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nothingFoundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Image_star")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var nothingFoundLabel: UILabel = {
        let label = UILabel()
        label.text = "Ничего не найдено"
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
        button.setTitle("Фильтры", for: .normal)
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
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 66, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 66, right: 0)
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
            
            filtersButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 114),
            filtersButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -114),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            
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
        let newHabitVC = NewHabitViewController()
        newHabitVC.delegate = self
        newHabitVC.modalPresentationStyle = .pageSheet
        present(newHabitVC, animated: true)
    }
    
    @objc private func filtersButtonTapped() {
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
            let today = Calendar.current.startOfDay(for: Date())
            let selectedDate = Calendar.current.startOfDay(for: currentDate)
            let isToday = Calendar.current.isDate(selectedDate, inSameDayAs: today)
            
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
                        return completedTrackers.contains { record in
                            record.id == tracker.id && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
                        }
                    case .notCompleted:
                        // Не завершенные трекеры на выбранную дату
                        return !completedTrackers.contains { record in
                            record.id == tracker.id && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
                        }
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
        
        // Скрываем кнопку фильтров, если нет трекеров на выбранный день
        filtersButton.isHidden = !hasTrackersForSelectedDate
        
        // Обновляем состояние пустого экрана
        let hasVisibleTrackers = !visibleCategories.isEmpty
        let hasActiveFilter = currentFilter != nil && currentFilter != .all && currentFilter != .today
        
        if hasActiveFilter && !hasVisibleTrackers {
            // Показываем "Ничего не найдено" если применен фильтр и ничего не найдено
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
            nothingFoundImageView.isHidden = false
            nothingFoundLabel.isHidden = false
            collectionView.isHidden = true
        } else if !hasVisibleTrackers {
            // Показываем стандартную заглушку если нет трекеров вообще
            emptyStateImageView.isHidden = false
            emptyStateLabel.isHidden = false
            nothingFoundImageView.isHidden = true
            nothingFoundLabel.isHidden = true
            collectionView.isHidden = true
        } else {
            // Есть трекеры для отображения
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
            nothingFoundImageView.isHidden = true
            nothingFoundLabel.isHidden = true
            collectionView.isHidden = false
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
        
        let completedDays = completedTrackers.filter { $0.id == tracker.id }.count
        
        let isCompletedToday = completedTrackers.contains { record in
            record.id == tracker.id && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
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
            label.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12)
        ])
        
        return header
    }
}

extension TrackersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return UIMenu(title: "", children: []) }
            let tracker = self.visibleCategories[indexPath.section].trackers[indexPath.item]
            
            let pinAction = UIAction(
                title: "Закрепить",
                image: UIImage(systemName: "pin")
            ) { _ in
                self.pinTracker(tracker, at: indexPath)
            }
            
            let editAction = UIAction(
                title: "Редактировать",
                image: UIImage(systemName: "pencil")
            ) { _ in
                self.editTracker(tracker, at: indexPath)
            }
            
            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self.deleteTracker(tracker, at: indexPath)
            }
            
            return UIMenu(title: "", children: [pinAction, editAction, deleteAction])
        }
    }
    
    private func pinTracker(_ tracker: Tracker, at indexPath: IndexPath) {
        // Заглушка для функциональности закрепления (дополнительная задача)
        print("Закрепить трекер: \(tracker.name)")
    }
    
    private func editTracker(_ tracker: Tracker, at indexPath: IndexPath) {
        // Заглушка для функциональности редактирования
        print("Редактировать трекер: \(tracker.name)")
    }
    
    private func deleteTracker(_ tracker: Tracker, at indexPath: IndexPath) {
        // Заглушка для функциональности удаления
        print("Удалить трекер: \(tracker.name)")
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
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
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
}

extension TrackersViewController: TrackerCellDelegate {
    func didTapPlusButton(for trackerId: UUID) {
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDate = Calendar.current.startOfDay(for: currentDate)
        
        guard selectedDate <= today else {
            return
        }
        
        let exists = completedTrackers.contains { record in
            record.id == trackerId && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
        }
        
        do {
            if exists {
                try trackerRecordStore.deleteRecord(trackerId: trackerId, date: currentDate)
                if let recordToRemove = completedTrackers.first(where: { record in
                    record.id == trackerId && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
                }) {
                    completedTrackers.remove(recordToRemove)
                }
            } else {
                _ = try trackerRecordStore.createRecord(trackerId: trackerId, date: currentDate)
                let newRecord = TrackerRecord(id: trackerId, date: currentDate)
                completedTrackers.insert(newRecord)
            }
            
            CoreDataStack.shared.saveContext()
            
            collectionView.reloadData()
        } catch {
            print("Ошибка при работе с записью: \(error)")
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
        
        // Если выбран "Все трекеры" или "Трекеры на сегодня", сбрасываем фильтр
        if filter == .all || filter == .today {
            currentFilter = nil
        } else {
            currentFilter = filter
        }
        filterTrackers()
    }
}

extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


