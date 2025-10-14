import UIKit
import RoomPlan
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // Proprietà per controllare l'orientamento
    var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Crea la finestra
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        // Verifica se RoomPlan è supportato
        if RoomCaptureSession.isSupported {
            // Mostra la UI principale
            let contentView = ContentView()
            window.rootViewController = UIHostingController(rootView: contentView)
        } else {
            // Mostra la schermata di dispositivo non supportato
            let unsupportedView = UnsupportedDeviceView()
            window.rootViewController = UIHostingController(rootView: unsupportedView)
        }
        
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
}
