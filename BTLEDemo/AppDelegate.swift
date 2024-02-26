//
//  AppDelegate.swift
//  BTLEDemo
//
//  Created by Lorenz Cunanan on 6/1/22.
//

import UIKit
import QuantumSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let developerKey = "YOUR_DEVELOPER_KEY_HERE"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Set developer key
        do {
            let ipciq = IPCIQ.register()
            try ipciq?.setDeveloperKey(developerKey)
        } catch {
            print("Developer Key Failed: \(error.localizedDescription)")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

