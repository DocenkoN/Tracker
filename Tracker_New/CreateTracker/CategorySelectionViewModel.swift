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
    
    func updateCategory(at indexPath: IndexPath, newTitle: String) {
        guard indexPath.row < categoriesData.count else { return }
        let oldTitle = categoriesData[indexPath.row]
        
        do {
            if let category = try categoryStore.fetchCategory(by: oldTitle) {
                try categoryStore.updateCategory(category, title: newTitle)
                CoreDataStack.shared.saveContext()
                
                // Если редактируемая категория была выбрана, обновляем selectedCategory
                if selectedCategory == oldTitle {
                    selectedCategory = newTitle
                }
                
                loadCategories()
            }
        } catch {
            errorMessage = "Ошибка обновления категории: \(error.localizedDescription)"
        }
    }
    
    func deleteCategory(at indexPath: IndexPath) {
        guard indexPath.row < categoriesData.count else { return }
        let categoryTitle = categoriesData[indexPath.row]
        
        do {
            if let category = try categoryStore.fetchCategory(by: categoryTitle) {
                try categoryStore.deleteCategory(category)
                CoreDataStack.shared.saveContext()
                
                // Если удаляемая категория была выбрана, сбрасываем выбор
                if selectedCategory == categoryTitle {
                    selectedCategory = nil
                }
                
                loadCategories()
            }
        } catch {
            errorMessage = "Ошибка удаления категории: \(error.localizedDescription)"
        }
    }
    
    func getCategoryTitle(at indexPath: IndexPath) -> String? {
        guard indexPath.row < categoriesData.count else { return nil }
        return categoriesData[indexPath.row]
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

