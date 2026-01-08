import UIKit

protocol NewCategoryViewControllerDelegate: AnyObject {
    func didCreateCategory(_ categoryTitle: String)
    func didUpdateCategory(_ categoryTitle: String, at indexPath: IndexPath)
}

final class NewCategoryViewController: UIViewController {
    
    weak var delegate: NewCategoryViewControllerDelegate?
    var editingIndexPath: IndexPath?
    var initialCategoryTitle: String?
    
    private lazy var categoryTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название категории"
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.enablesReturnKeyAutomatically = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    private lazy var backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0) : 
                UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        }
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }, for: .normal)
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
        
        // Если редактируем - заполняем поле
        if editingIndexPath != nil {
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
        view.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        
        let title = editingIndexPath != nil ? "Редактирование категории" : "Новая категория"
        navigationItem.title = title
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? .white : .black
            },
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        navigationItem.hidesBackButton = true
        
        view.addSubview(backgroundContainerView)
        backgroundContainerView.addSubview(categoryTextField)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            backgroundContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backgroundContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backgroundContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            backgroundContainerView.heightAnchor.constraint(equalToConstant: 75),
            
            categoryTextField.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor, constant: 16),
            categoryTextField.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor, constant: -12),
            categoryTextField.centerYAnchor.constraint(equalTo: backgroundContainerView.centerYAnchor),
            
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
        let activeColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0)
        }
        
        UIView.animate(withDuration: 0.2) {
            self.doneButton.backgroundColor = hasText ? activeColor : inactiveColor
            self.doneButton.setTitleColor(UIColor { traitCollection in
                if hasText {
                    return traitCollection.userInterfaceStyle == .dark ? .black : .white
                } else {
                    return .white
                }
            }, for: .normal)
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

