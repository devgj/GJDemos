//
//  NewsHomeViewController.swift
//  GJDemos
//
//  Created by GJ on 16/1/6.
//  Copyright © 2016年 GJ. All rights reserved.
//

import UIKit
import SnapKit

class NewsHomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        let tabBarController = CustomTabBarController()
        tabBarController.dataSource = self
        self.addChildViewController(tabBarController)
        self.view.addSubview(tabBarController.view)
        tabBarController.view.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(64)
            make.left.right.bottom.equalTo(self.view)
        }
    }
}

extension NewsHomeViewController: CustomTabBarControllerDataSource {
    func itemsOfCustomTabBarController(controller: CustomTabBarController) -> [CustomTabBarItem] {
        
        return [
            CustomTabBarItem(title: "头条", viewController: TestTableViewController()),
            CustomTabBarItem(title: "轻松一刻", viewController: TestTableViewController()),
            CustomTabBarItem(title: "科技", viewController: TestTableViewController()),
            CustomTabBarItem(title: "娱乐", viewController: TestTableViewController()),
            CustomTabBarItem(title: "体育", viewController: TestTableViewController()),
            CustomTabBarItem(title: "财经", viewController: TestTableViewController()),
            CustomTabBarItem(title: "汽车", viewController: TestTableViewController()),
        ]
    }
}
