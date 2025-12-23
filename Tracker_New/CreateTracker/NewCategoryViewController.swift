import UIKit

protocol NewCategoryViewControllerDelegate: AnyObject {
    func didCreateCategory(_ categoryTitle: String)
    func didUpdateCategory(_ categoryTitle: String, at indexPath: IndexPath)
}

final class NewCategoryViewController: UIViewController {
    
    weak var delegate: NewCategoryViewControllerDelegate?
    var editingIndexPath: IndexPath?
    var initialCategoryTitle: String?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая категория"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var categoryTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название категории"
        textField.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        textField.layer.cornerRadius = 16
        textField.font = .systemFont(ofSize: 17)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 75))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1.0)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Если редактируем - обновляем заголовок и заполняем поле
        if editingIndexPath != nil {
            titleLabel.text = "Редактирование категории"
            if let initialTitle = initialCategoryTitle {
                categoryTextField.text = initialTitle
                textFieldDidChange() // Обновляем состояние кнопки "Готово"
            }
        }
        
        categoryTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        categoryTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Используем небольшую задержку для корректной работы с физической клавиатурой
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if self.categoryTextField.canBecomeFirstResponder {
                self.categoryTextField.becomeFirstResponder()
            }
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(titleLabel)
        view.addSubview(categoryTextField)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            categoryTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            categoryTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryTextField.heightAnchor.constraint(equalToConstant: 75),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func textFieldDidChange() {
        let text = categoryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasText = !text.isEmpty
        
        doneButton.isEnabled = hasText
        
        let inactiveColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1.0)
        let activeColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0)
        
        UIView.animate(withDuration: 0.2) {
            self.doneButton.backgroundColor = hasText ? activeColor : inactiveColor
        }
    }
    
    @objc private func doneButtonTapped() {
        guard let text = categoryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        
        if let indexPath = editingIndexPath {
            delegate?.didUpdateCategory(text, at: indexPath)
        } else {
            delegate?.didCreateCategory(text)
        }
        
        dismiss(animated: true)
    }
}

extension NewCategoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if doneButton.isEnabled {
            doneButtonTapped()
        }
        return true
    }
}

