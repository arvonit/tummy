//
//  TabBarController.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let feed = makeTab(
            PlaceholderViewController(title: "Feed"),
            title: "Feed",
            imageName: "list.bullet.rectangle"
        )
        // One store, so rankings changed in one tab show up in the other
        let rankingStore = SampleRankingStore()
        let myLists = makeTab(
            MyListsViewController(store: rankingStore),
            title: "My Lists",
            imageName: "list.number"
        )
        let search = makeTab(
            SearchViewController(rankingStore: rankingStore),
            title: "Search",
            imageName: "map"
        )
        let profile = makeTab(
            PlaceholderViewController(title: "Profile"),
            title: "Profile",
            imageName: "person.crop.circle"
        )

        viewControllers = [feed, myLists, search, profile]
        // Start on Search while it's the screen under development
        selectedViewController = search
    }

    func makeTab(
        _ rootViewController: UIViewController,
        title: String,
        imageName: String
    ) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: nil
        )
        return navigationController
    }

}

#Preview {
    TabBarController()
}
