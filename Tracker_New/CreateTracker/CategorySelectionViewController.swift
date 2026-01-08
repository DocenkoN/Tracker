import UIKit

protocol CategorySelectionViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

final class CategorySelectionViewController: UIViewController {
    
    weak var delegate: CategorySelectionViewControllerDelegate?
    
    private let viewModel: CategorySelectionViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
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
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
        button.setTitleColor(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addCategoryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Image_star")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0)
        }
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    init(viewModel: CategorySelectionViewModel? = nil, selectedCategory: String? = nil) {
        if let viewModel = viewModel {
            self.viewModel = viewModel
        } else {
            self.viewModel = CategorySelectionViewModel(initialSelectedCategory: selectedCategory)
        }
        super.init(nibName: nil, bundle: nil)
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateEmptyState()
        updateAddCategoryButton()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        
        navigationItem.title = "Категория"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .white : .black
            },
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        navigationItem.hidesBackButton = true
        
        view.addSubview(tableView)
        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)
        view.addSubview(addCategoryButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addCategoryButton.topAnchor, constant: -16),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
    }
    
    private func setupBindings() {
        viewModel.cellModelsBinding = { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateEmptyState()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.selectedCategoryBinding = { [weak self] category in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateAddCategoryButton()
            }
        }
        
        viewModel.errorBinding = { [weak self] errorMessage in
            guard let errorMessage = errorMessage else { return }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Ошибка", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
        
        // Принудительно обновляем состояние после установки binding
        // так как данные могли загрузиться до установки binding
        DispatchQueue.main.async { [weak self] in
            self?.updateEmptyState()
            self?.updateAddCategoryButton()
            self?.tableView.reloadData()
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = viewModel.numberOfRows() == 0
        tableView.isHidden = isEmpty
        emptyStateImageView.isHidden = !isEmpty
        emptyStateLabel.isHidden = !isEmpty
        
        // Убеждаемся, что элементы видны когда нужно
        if isEmpty {
            emptyStateImageView.alpha = 1.0
            emptyStateLabel.alpha = 1.0
        }
    }
    
    private func updateAddCategoryButton() {
        // По макету кнопка всегда белая в темной теме, независимо от выбора категории
        UIView.animate(withDuration: 0.2) {
            self.addCategoryButton.backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .white : .black
            }
            self.addCategoryButton.setTitleColor(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .black : .white
            }, for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEmptyState()
        updateAddCategoryButton()
    }
    
    @objc private func addCategoryButtonTapped() {
        // Если категория выбрана - подтверждаем выбор
        if let selectedCategory = viewModel.selectedCategory {
            delegate?.didSelectCategory(selectedCategory)
            dismiss(animated: true)
        } else {
            // Если категория не выбрана - открываем экран создания новой категории
            let newCategoryVC = NewCategoryViewController()
            newCategoryVC.delegate = self
            newCategoryVC.modalPresentationStyle = .pageSheet
            present(newCategoryVC, animated: true)
        }
    }
}

extension CategorySelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.identifier, for: indexPath) as? CategoryCell,
              let cellModel = viewModel.cellModel(at: indexPath) else {
            return UITableViewCell()
        }
        
        let numberOfRows = viewModel.numberOfRows()
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == numberOfRows - 1
        
        cell.configure(title: cellModel.title, isSelected: cellModel.isSelected, isFirst: isFirst, isLast: isLast)
        
        return cell
    }
}

extension CategorySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectCategory(at: indexPath)
        
        // Обновляем визуально выбранную категорию
        tableView.reloadData()
        updateAddCategoryButton()
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let editAction = UIAction(
                title: "Редактировать",
                image: UIImage(systemName: "pencil")
            ) { _ in
                self?.editCategory(at: indexPath)
            }
            
            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.showDeleteConfirmation(for: indexPath)
            }
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
    
    private func editCategory(at indexPath: IndexPath) {
        guard let categoryTitle = viewModel.getCategoryTitle(at: indexPath) else { return }
        
        let editCategoryVC = NewCategoryViewController()
        editCategoryVC.initialCategoryTitle = categoryTitle
        editCategoryVC.editingIndexPath = indexPath
        editCategoryVC.delegate = self
        editCategoryVC.modalPresentationStyle = .pageSheet
        present(editCategoryVC, animated: true)
    }
    
    private func showDeleteConfirmation(for indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Эта категория точно не нужна?",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: indexPath)
        }
        
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // Для iPad нужно указать sourceView
        if let cell = tableView.cellForRow(at: indexPath) {
            alert.popoverPresentationController?.sourceView = cell
            alert.popoverPresentationController?.sourceRect = cell.bounds
        }
        
        present(alert, animated: true)
    }
}

extension CategorySelectionViewController: NewCategoryViewControllerDelegate {
    func didCreateCategory(_ categoryTitle: String) {
        viewModel.createCategory(title: categoryTitle)
    }
    
    func didUpdateCategory(_ categoryTitle: String, at indexPath: IndexPath) {
        viewModel.updateCategory(at: indexPath, newTitle: categoryTitle)
    }
}

