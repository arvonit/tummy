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
        let myLists = makeTab(MyListsViewController(), title: "My Lists", imageName: "list.number")
        let search = makeTab(
            PlaceholderViewController(title: "Search"),
            title: "Search",
            imageName: "map"
        )
        let profile = makeTab(
            PlaceholderViewController(title: "Profile"),
            title: "Profile",
            imageName: "person.crop.circle"
        )

        viewControllers = [feed, myLists, search, profile]
        // Start on My Lists while it's the screen under development
        selectedViewController = myLists
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
