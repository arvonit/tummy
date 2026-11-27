//
//  SearchViewController.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI
import UIKit

/// Hosts the SwiftUI search map, and opens the Place screen and the rate flow from it
class SearchViewController: UIViewController {

    let context: AppContext

    init(context: AppContext = AppContext()) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configViewController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The map fills the screen, so the bar only shows on screens pushed from here
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func configViewController() {
        let map = UIHostingController(rootView: SearchMapView(
            context: context,
            onOpen: { [weak self, context] in self?.showPlace($0.place, context: context) },
            onRank: { [weak self, context] in self?.presentRateFlow(for: $0, context: context) }
        ))
        map.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(map)
        view.addSubview(map.view)
        map.didMove(toParent: self)

        NSLayoutConstraint.activate([
            map.view.topAnchor.constraint(equalTo: view.topAnchor),
            map.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            map.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            map.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

}

#Preview {
    UINavigationController(rootViewController: SearchViewController())
}
