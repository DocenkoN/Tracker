import UIKit

final class TabBarController: UITabBarController {
    
    private var topBorder: CALayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
    
    @available(iOS, deprecated: 17.0, message: "Dynamic colors update automatically in iOS 17+")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateAppearance()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateAppearance()
        }, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTopBorder()
    }
    
    private func setupTabs() {
        let trackersVC = TrackersViewController()
        let trackersNavController = UINavigationController(rootViewController: trackersVC)
        trackersNavController.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Trackers", comment: "Trackers tab"),
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: nil
        )
        
        let statisticsVC = StatisticsViewController()
        let statisticsNavController = UINavigationController(rootViewController: statisticsVC)
        statisticsNavController.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Statistics", comment: "Statistics tab"),
            image: UIImage(systemName: "hare.fill"),
            selectedImage: nil
        )
        
        viewControllers = [trackersNavController, statisticsNavController]
    }
    
    private func setupAppearance() {
        updateAppearance()
    }
    
    private func updateAppearance() {
        tabBar.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0) :
                UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        }
        tabBar.barTintColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1.0) :
                UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        }
        tabBar.tintColor = UIColor(red: 0.22, green: 0.45, blue: 0.91, alpha: 1.0)
        tabBar.unselectedItemTintColor = UIColor(red: 0.68, green: 0.69, blue: 0.71, alpha: 1.0)
        
        updateTopBorder()
    }
    
    private func updateTopBorder() {
        topBorder?.removeFromSuperlayer()
        
        let border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5)
        
        let borderColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 82/255, green: 82/255, blue: 84/255, alpha: 1.0) :
                UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1.0)
        }
        border.backgroundColor = borderColor.cgColor
        tabBar.layer.addSublayer(border)
        topBorder = border
    }
}

