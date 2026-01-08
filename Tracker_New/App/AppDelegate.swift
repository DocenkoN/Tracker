import UIKit
import YandexMobileMetrica

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = CoreDataStack.shared.persistentContainer
        
        // Инициализация AppMetrica
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AppMetricaAPIKey") as? String, 
           !apiKey.isEmpty,
           apiKey != "1dacc71e-7abc-4a00-afef-111d84f2b9d6",
           let configuration = YMMYandexMetricaConfiguration(apiKey: apiKey) {
            YMMYandexMetrica.activate(with: configuration)
        }
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }


}

