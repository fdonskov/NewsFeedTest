//
//  SceneDelegate.swift
//  NewsFeedTest
//
//  Created by Fedor Donskov on 16.12.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(rootViewController: NewsPageViewController())
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

