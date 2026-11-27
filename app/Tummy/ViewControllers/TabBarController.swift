//
//  TabBarController.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import UIKit

class TabBarController: UITabBarController {

    // One set of stores, so a change made in one tab shows up in the others
    let context = AppContext()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = [
            makeTab(
                FeedViewController(context: context),
                title: "Feed",
                imageName: "list.bullet.rectangle"
            ),
            makeTab(
                MyListsViewController(context: context),
                title: "My Lists",
                imageName: "list.number"
            ),
            makeTab(SearchViewController(context: context), title: "Search", imageName: "map"),
            makeTab(
                ProfileViewController(user: context.userStore.currentUser, context: context),
                title: "Profile",
                imageName: "person.crop.circle"
            ),
        ]
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
