import UIKit

final class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
    
    private func setupTabs() {
        let trackersViewController = TrackersViewController()
        let trackersIcon = UIImage(systemName: "record.circle.fill")
        trackersViewController.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: trackersIcon,
            selectedImage: trackersIcon
        )
        
        let statisticsViewController = StatisticsViewController()
        let statsIcon = UIImage(systemName: "hare.fill")
        statisticsViewController.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: statsIcon,
            selectedImage: statsIcon
        )
        
        viewControllers = [trackersViewController, statisticsViewController]
    }
    
    private func setupAppearance() {
        tabBar.backgroundColor = .white
        tabBar.tintColor = UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0) // Синий цвет
        tabBar.unselectedItemTintColor = .gray
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5)
        topBorder.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        tabBar.layer.addSublayer(topBorder)
    }
}

