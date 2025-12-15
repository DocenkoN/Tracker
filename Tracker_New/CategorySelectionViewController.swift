import UIKit

protocol CategorySelectionViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

final class CategorySelectionViewController: UIViewController {
    
    weak var delegate: CategorySelectionViewControllerDelegate?
    
    private let viewModel: CategorySelectionViewModel
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Категория"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        tableView.layer.cornerRadius = 16
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .black
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addCategoryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var selectedCategoryTitle: String?
    
    init(viewModel: CategorySelectionViewModel = CategorySelectionViewModel(), selectedCategory: String? = nil) {
        self.viewModel = viewModel
        self.selectedCategoryTitle = selectedCategory
        super.init(nibName: nil, bundle: nil)
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(addCategoryButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addCategoryButton.topAnchor, constant: -16),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupBindings() {
        viewModel.categoriesBinding = { [weak self] categories in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        viewModel.selectedCategoryBinding = { [weak self] category in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
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
    }
    
    @objc private func addCategoryButtonTapped() {
        let alert = UIAlertController(title: "Новая категория", message: "Введите название категории", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Название категории"
        }
        
        let createAction = UIAlertAction(title: "Создать", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let text = textField.text,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            self?.viewModel.createCategory(title: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

extension CategorySelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = viewModel.categories[indexPath.row]
        
        cell.textLabel?.text = category
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        if category == selectedCategoryTitle || category == viewModel.selectedCategory {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
}

extension CategorySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = viewModel.categories[indexPath.row]
        viewModel.selectCategory(category)
        delegate?.didSelectCategory(category)
        dismiss(animated: true)
    }
}

