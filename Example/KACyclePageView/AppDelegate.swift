//
//  AppDelegate.swift
//  KACyclePageView
//
//  Created by zhihuazhang on 06/21/2016.
//  Copyright © 2016年 Kapps Inc. All rights reserved.
//

import UIKit
import KACyclePageView

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let vc = KACyclePageView.cyclePageView(dataSource: DataSource())
        
        window?.rootViewController = vc
        
        return true
    }

}
