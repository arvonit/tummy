//
//  PlaceholderViewController.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import UIKit

/// Stands in for tabs that haven't been built yet
class PlaceholderViewController: UIViewController {

    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        var content = UIContentUnavailableConfiguration.empty()
        content.image = UIImage(systemName: "hammer")
        content.text = "Coming soon"
        content.secondaryText = "\(title ?? "This tab") isn't built yet."
        contentUnavailableConfiguration = content
    }

}
