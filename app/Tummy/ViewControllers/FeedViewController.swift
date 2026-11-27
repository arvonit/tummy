//
//  FeedViewController.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI
import UIKit

/// Your visits and those of people you follow, newest first
class FeedViewController: UIViewController, UICollectionViewDelegate {

    let context: AppContext

    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Int, FeedItem.ID>!
    var itemsByID: [FeedItem.ID: FeedItem] = [:]

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
        configCollectionView()
        configDataSource()
    }

    /// Runs again whenever the rankings, visits, or follows it reads change
    override func updateProperties() {
        super.updateProperties()
        let me = context.currentUserID
        applySnapshot(context.feedItems(showing: Set(context.userStore.following(of: me) + [me])))
    }

    func configViewController() {
        title = "Feed"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func configCollectionView() {
        let layout = UICollectionViewCompositionalLayout.list(
            using: UICollectionLayoutListConfiguration(appearance: .plain)
        )
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func configDataSource() {
        let context = context
        let feedCell = ViewHelper.makeFeedCell(
            onOpenUser: { [weak self] in self?.showProfile(of: $0, context: context) },
            onRank: { [weak self] item in
                let summary = context.summary(for: item.ranking.ranking)
                self?.presentRateFlow(for: summary, context: context)
            }
        )

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            [weak self] collectionView, indexPath, id in
            guard let item = self?.itemsByID[id] else { return nil }
            return collectionView.dequeueConfiguredReusableCell(
                using: feedCell,
                for: indexPath,
                item: item
            )
        }
    }

    func applySnapshot(_ items: [FeedItem]) {
        itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Int, FeedItem.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(items.map(\.id))
        // Scores shift as lists change, so redraw the items that stayed
        let previousIDs = Set(dataSource.snapshot().itemIdentifiers)
        snapshot.reconfigureItems(items.map(\.id).filter(previousIDs.contains))

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath), let item = itemsByID[id] else {
            return
        }
        showPlace(Place(item.ranking.ranking), context: context)
    }

}

#Preview {
    UINavigationController(rootViewController: FeedViewController())
}
