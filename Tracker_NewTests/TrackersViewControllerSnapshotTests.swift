import XCTest
import SnapshotTesting
@testable import Tracker_New

final class TrackersViewControllerSnapshotTests: XCTestCase {

    func testTrackersViewControllerLightTheme() {
        let vc = TrackersViewController()
        // Устанавливаем размер view для корректного скриншота
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()
        
        assertSnapshot(of: vc, as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .light)))
    }

    func testTrackersViewControllerDarkTheme() {
        let vc = TrackersViewController()
        // Устанавливаем размер view для корректного скриншота
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()
        
        assertSnapshot(of: vc, as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark)))
    }
    
    func testTrackersViewControllerLightThemeWithChangedBackground() {
        let vc = TrackersViewController()
        // Устанавливаем размер view для корректного скриншота
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        // Изменяем background для проверки, что тест падает
        vc.view.backgroundColor = .red
        vc.view.layoutIfNeeded()
        
        assertSnapshot(of: vc, as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .light)))
    }
}

