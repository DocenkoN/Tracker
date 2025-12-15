import Foundation

final class CategorySelectionViewModel {
    
    var categories: [String] = [] {
        didSet {
            categoriesBinding?(categories)
        }
    }
    
    var selectedCategory: String? {
        didSet {
            selectedCategoryBinding?(selectedCategory)
        }
    }
    
    var errorMessage: String? {
        didSet {
            errorBinding?(errorMessage)
        }
    }
    
    var categoriesBinding: (([String]) -> Void)?
    var selectedCategoryBinding: ((String?) -> Void)?
    var errorBinding: ((String?) -> Void)?
    
    private let categoryStore: TrackerCategoryStore
    
    init(categoryStore: TrackerCategoryStore = TrackerCategoryStore()) {
        self.categoryStore = categoryStore
        loadCategories()
    }
    
    func loadCategories() {
        do {
            let categoriesCoreData = try categoryStore.fetchCategories()
            categories = categoriesCoreData.compactMap { $0.title }
        } catch {
            errorMessage = "Ошибка загрузки категорий: \(error.localizedDescription)"
        }
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
    }
    
    func createCategory(title: String) {
        do {
            _ = try categoryStore.createCategory(title: title)
            CoreDataStack.shared.saveContext()
            loadCategories()
        } catch {
            errorMessage = "Ошибка создания категории: \(error.localizedDescription)"
        }
    }
}

