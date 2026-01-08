import XCTest
import SnapshotTesting
@testable import Tracker_New

final class TrackersViewControllerSnapshotTests: XCTestCase {

    func testTrackersViewControllerLightTheme() {
        let vc = TrackersViewController()

        assertSnapshot(of: vc, as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .light)))
    }

    func testTrackersViewControllerDarkTheme() {
        let vc = TrackersViewController()

        assertSnapshot(of: vc, as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark)))
    }
}

