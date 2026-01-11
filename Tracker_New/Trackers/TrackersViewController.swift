import UIKit
import YandexMobileMetrica

final class TrackersViewController: UIViewController {
    
    var categories: [TrackerCategory] = []
    var completedTrackers: Set<TrackerRecord> = []
    private var visibleCategories: [TrackerCategory] = []
    private var searchText: String = ""
    private var currentFilter: TrackerFilter? = .all
    
    private let trackerStore = TrackerStore()
    private let trackerCategoryStore = TrackerCategoryStore()
    private let trackerRecordStore = TrackerRecordStore()
    
    private var currentDate = Date() {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy"
            dateLabel.text = dateFormatter.string(from: currentDate)
            filterTrackers()
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        picker.locale = Locale(identifier: "ru_RU")
        picker.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1.0) :
                UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        }
        picker.layer.cornerRadius = 8
        picker.clipsToBounds = true
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        label.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1.0) :
                UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        }
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 8
        label.text = dateFormatter.string(from: currentDate)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var dateContainerView: UIView = {
        let view = UIView()
        view.addSubview(datePicker)
        view.insertSubview(dateLabel, aboveSubview: datePicker)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = NSLocalizedString("Search", comment: "Search placeholder")
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        if let searchTextField = controller.searchBar.value(forKey: "searchField") as? UITextField {
            searchTextField.backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                    UIColor(red: 118/255, green: 118/255, blue: 128/255, alpha: 0.24) :
                    UIColor(red: 118/255, green: 118/255, blue: 128/255, alpha: 0.12)
            }
            searchTextField.layer.cornerRadius = 10
            searchTextField.clipsToBounds = true
        }
        return controller
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
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
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)
        view.addSubview(nothingFoundImageView)
        view.addSubview(nothingFoundLabel)
        view.addSubview(filtersButton)
        
        setupNavigationBar()
        setupCollectionView()
        setupConstraints()
        searchController.searchResultsUpdater = self
    }
    
    private func setupNavigationBar() {
        setupDatePickerConstraints()
        
        let dateBarButtonItem = UIBarButtonItem(customView: dateContainerView)
        let plusBarButtonItem = UIBarButtonItem(customView: addButton)
        navigationItem.leftBarButtonItem = plusBarButtonItem
        navigationItem.rightBarButtonItem = dateBarButtonItem
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .white : .black
            },
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        navigationItem.title = NSLocalizedString("Trackers", comment: "Main screen title")
        navigationItem.largeTitleDisplayMode = .always
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupDatePickerConstraints() {
        NSLayoutConstraint.activate([
            dateContainerView.widthAnchor.constraint(equalToConstant: 77),
            dateContainerView.heightAnchor.constraint(equalToConstant: 34),
            
            datePicker.topAnchor.constraint(equalTo: dateContainerView.topAnchor),
            datePicker.leadingAnchor.constraint(equalTo: dateContainerView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: dateContainerView.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: dateContainerView.bottomAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: dateContainerView.topAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: dateContainerView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: dateContainerView.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: dateContainerView.bottomAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            filtersButton.widthAnchor.constraint(equalToConstant: 114),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            nothingFoundImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            nothingFoundImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            nothingFoundImageView.widthAnchor.constraint(equalToConstant: 80),
            nothingFoundImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nothingFoundLabel.topAnchor.constraint(equalTo: nothingFoundImageView.bottomAnchor, constant: 8),
            nothingFoundLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nothingFoundLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func addButtonTapped() {
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
        DispatchQueue.main.async { [weak self] in
            self?.hideDatePickerText()
        }
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
        
        var filteredByScheduleAndSearch: [TrackerCategory] = categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                let matchesSchedule: Bool
                if tracker.schedule.isEmpty {
                    matchesSchedule = true
                } else {
                    matchesSchedule = tracker.schedule.contains(currentWeekDay)
                }
                
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
        
        if let filter = currentFilter {
            filteredByScheduleAndSearch = filteredByScheduleAndSearch.compactMap { category in
                let filteredTrackers = category.trackers.filter { tracker in
                    switch filter {
                    case .all:
                        return true
                    case .today:
                        return true
                    case .completed:
                        return isCompleted(id: tracker.id, date: currentDate)
                    case .notCompleted:
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
        
        let hasVisibleTrackers = !visibleCategories.isEmpty
        let hasActiveFilter = currentFilter != nil && currentFilter != .all && currentFilter != .today
        let hasActiveSearch = !searchText.isEmpty
        let showNothingFound = (hasActiveFilter || hasActiveSearch) && !hasVisibleTrackers
        
        if showNothingFound {
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
            nothingFoundImageView.isHidden = false
            nothingFoundLabel.isHidden = false
            collectionView.isHidden = true
            filtersButton.isHidden = true
        } else if !hasVisibleTrackers {
            emptyStateImageView.isHidden = false
            emptyStateLabel.isHidden = false
            nothingFoundImageView.isHidden = true
            nothingFoundLabel.isHidden = true
            collectionView.isHidden = true
            filtersButton.isHidden = !hasTrackersForSelectedDate
        } else {
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
            nothingFoundImageView.isHidden = true
            nothingFoundLabel.isHidden = true
            collectionView.isHidden = false
            filtersButton.isHidden = !hasTrackersForSelectedDate
        }
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
        let parameters: [String: Any] = [
            "event": "click",
            "screen": "Main",
            "item": "edit"
        ]
        YMMYandexMetrica.reportEvent("click", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: click, screen: Main, item: edit")
        #endif
        
        var categoryTitle = ""
        for category in categories {
            if category.trackers.contains(where: { $0.id == tracker.id }) {
                categoryTitle = category.title
                break
            }
        }
        
        let completedDaysCount = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
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
        let parameters: [String: Any] = [
            "event": "click",
            "screen": "Main",
            "item": "delete"
        ]
        YMMYandexMetrica.reportEvent("click", parameters: parameters)
        #if DEBUG
        print("[Analytics] event: click, screen: Main, item: delete")
        #endif
        
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
        
        if let popover = alert.popoverPresentationController {
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
            try trackerRecordStore.deleteRecords(for: tracker.id)
            
            if let trackerCoreData = try trackerStore.fetchTracker(by: tracker.id) {
                try trackerStore.deleteTracker(trackerCoreData)
            }
            
            CoreDataStack.shared.saveContext()
            
            loadCategories()
            loadCompletedTrackers()
            filterTrackers()
        } catch {
            print("Ошибка удаления трекера: \(error)")
            
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
        let availableWidth = collectionView.frame.width - 32 - 9
        let cellWidth = availableWidth / 2
        return CGSize(width: cellWidth, height: 148)
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
    
    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell else {
            return nil
        }
        
        return UITargetedPreview(view: cell.getColorView())
    }
    
    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell else {
            return nil
        }
        
        return UITargetedPreview(view: cell.getColorView())
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
            
            guard let colorHex = tracker.color.toHex() else {
                return
            }
            
            var categoryCoreData = try trackerCategoryStore.fetchCategory(by: categoryTitle)
            if categoryCoreData == nil {
                categoryCoreData = try trackerCategoryStore.createCategory(title: categoryTitle)
            }
            
            guard let categoryCoreData = categoryCoreData else {
                return
            }
            
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
        
        let isCompleted = isCompleted(id: trackerId, date: currentDate)
        
        do {
            if isCompleted {
                try trackerRecordStore.deleteRecord(trackerId: trackerId, date: normalizedDate)
                
                if let recordToRemove = completedTrackers.first(where: { existingRecord in
                    existingRecord.trackerId == trackerId && calendar.isDate(existingRecord.date, inSameDayAs: normalizedDate)
                }) {
                    completedTrackers.remove(recordToRemove)
                }
            } else {
                try trackerRecordStore.addRecord(trackerId: trackerId, date: normalizedDate)
                let record = TrackerRecord(trackerId: trackerId, date: normalizedDate)
                completedTrackers.insert(record)
            }
            
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
        
        currentFilter = filter
        filterTrackers()
    }
}

extension TrackersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        filterTrackers()
    }
}


