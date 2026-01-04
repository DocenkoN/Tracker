import UIKit

final class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
    
    private func setupTabs() {
        let trackersVC = TrackersViewController()
        let trackersNavController = UINavigationController(rootViewController: trackersVC)
        trackersNavController.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: nil
        )
        
        let statisticsVC = StatisticsViewController()
        let statisticsNavController = UINavigationController(rootViewController: statisticsVC)
        statisticsNavController.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare.fill"),
            selectedImage: nil
        )
        
        viewControllers = [trackersNavController, statisticsNavController]
    }
    
    private func setupAppearance() {
        tabBar.backgroundColor = .white
        tabBar.tintColor = UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0)
        tabBar.unselectedItemTintColor = UIColor(red: 0.68, green: 0.69, blue: 0.71, alpha: 1.0)
        
        // Добавляем верхнюю границу
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5)
        topBorder.backgroundColor = UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1.0).cgColor
        tabBar.layer.addSublayer(topBorder)
    }
}

