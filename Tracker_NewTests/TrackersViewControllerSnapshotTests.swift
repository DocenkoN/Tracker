import XCTest
@testable import Tracker_New

final class TrackersViewControllerSnapshotTests: XCTestCase {
    
    var viewController: TrackersViewController!
    var window: UIWindow!
    
    override func setUp() {
        super.setUp()
        viewController = TrackersViewController()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
    
    override func tearDown() {
        window = nil
        viewController = nil
        super.tearDown()
    }
    
    func testTrackersViewControllerLightMode() throws {
        // Настройка для светлой темы
        viewController.overrideUserInterfaceStyle = .light
        window.overrideUserInterfaceStyle = .light
        
        // Убеждаемся, что view загружена и отрисована
        viewController.loadViewIfNeeded()
        viewController.viewDidLoad()
        
        // Ждем отрисовки
        let expectation = expectation(description: "View rendered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Делаем скриншот через renderer
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        let attachment = XCTAttachment(image: image)
        attachment.name = "TrackersViewController_light"
        attachment.lifetime = XCTAttachment.Lifetime.keepAlways
        add(attachment)
    }
    
    func testTrackersViewControllerDarkMode() throws {
        // Настройка для темной темы
        viewController.overrideUserInterfaceStyle = .dark
        window.overrideUserInterfaceStyle = .dark
        
        // Убеждаемся, что view загружена и отрисована
        viewController.loadViewIfNeeded()
        viewController.viewDidLoad()
        
        // Ждем отрисовки
        let expectation = expectation(description: "View rendered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Делаем скриншот через renderer
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        let attachment = XCTAttachment(image: image)
        attachment.name = "TrackersViewController_dark"
        attachment.lifetime = XCTAttachment.Lifetime.keepAlways
        add(attachment)
    }
}

