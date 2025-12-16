import Foundation

struct CategoryCellModel {
    let title: String
    let isSelected: Bool
}

final class CategorySelectionViewModel {
    
    private var categoriesData: [String] = [] {
        didSet {
            updateCellModels()
        }
    }
    
    private var cellModels: [CategoryCellModel] = [] {
        didSet {
            cellModelsBinding?(cellModels)
        }
    }
    
    var selectedCategory: String? {
        didSet {
            updateCellModels()
            selectedCategoryBinding?(selectedCategory)
        }
    }
    
    var errorMessage: String? {
        didSet {
            errorBinding?(errorMessage)
        }
    }
    
    var cellModelsBinding: (([CategoryCellModel]) -> Void)?
    var selectedCategoryBinding: ((String?) -> Void)?
    var errorBinding: ((String?) -> Void)?
    
    private let categoryStore: TrackerCategoryStore
    
    init(categoryStore: TrackerCategoryStore = TrackerCategoryStore(), initialSelectedCategory: String? = nil) {
        self.categoryStore = categoryStore
        self.selectedCategory = initialSelectedCategory
        loadCategories()
    }
    
    func loadCategories() {
        do {
            let categoriesCoreData = try categoryStore.fetchCategories()
            categoriesData = categoriesCoreData.compactMap { $0.title }
        } catch {
            errorMessage = "Ошибка загрузки категорий: \(error.localizedDescription)"
        }
    }
    
    func numberOfRows() -> Int {
        return cellModels.count
    }
    
    func cellModel(at indexPath: IndexPath) -> CategoryCellModel? {
        guard indexPath.row < cellModels.count else { return nil }
        return cellModels[indexPath.row]
    }
    
    func selectCategory(at indexPath: IndexPath) {
        guard indexPath.row < categoriesData.count else { return }
        let category = categoriesData[indexPath.row]
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
    
    private func updateCellModels() {
        cellModels = categoriesData.map { categoryTitle in
            CategoryCellModel(
                title: categoryTitle,
                isSelected: categoryTitle == selectedCategory
            )
        }
    }
}

