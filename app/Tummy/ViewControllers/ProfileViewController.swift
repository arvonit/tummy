//
//  ProfileViewController.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI
import UIKit

/// A person's header, score stats, and activity. Read-only for people other than you.
class ProfileViewController: UIViewController, UICollectionViewDelegate {

    // nonisolated so diffable data sources can hash it off the main actor
    nonisolated enum Item: Hashable {
        case header
        case stats
        case visit(Visit.ID)
    }

    let user: User
    let context: AppContext

    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Int, Item>!
    var rankings: [ScoredRanking] = []
    var itemsByID: [FeedItem.ID: FeedItem] = [:]

    var isCurrentUser: Bool { user.id == context.currentUserID }

    init(user: User, context: AppContext = AppContext()) {
        self.user = user
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
        rankings = ScoreCurve.scored(context.rankingStore.rankings.filter { $0.userID == user.id })
        applySnapshot(context.feedItems(showing: [user.id]))
    }

    func configViewController() {
        // Not `title`, which would also rename the Profile tab
        navigationItem.title = user.name
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
        let headerCell = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
            [weak self] cell, _, _ in
            guard let self else { return }
            cell.contentConfiguration = UIHostingConfiguration { self.makeHeader() }
        }
        let statsCell = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
            [weak self] cell, _, _ in
            guard let self else { return }
            cell.contentConfiguration = UIHostingConfiguration {
                ProfileStatsView(rankings: self.rankings)
            }
        }
        let feedCell = ViewHelper.makeFeedCell(
            // Already on this person's profile
            onOpenUser: { _ in },
            onRank: { [weak self] item in
                let summary = context.summary(for: item.ranking.ranking)
                self?.presentRateFlow(for: summary, context: context)
            }
        )

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            [weak self] collectionView, indexPath, item in
            switch item {
            case .header:
                collectionView.dequeueConfiguredReusableCell(
                    using: headerCell, for: indexPath, item: item
                )
            case .stats:
                collectionView.dequeueConfiguredReusableCell(
                    using: statsCell, for: indexPath, item: item
                )
            case .visit(let id):
                self?.itemsByID[id].map {
                    collectionView.dequeueConfiguredReusableCell(
                        using: feedCell, for: indexPath, item: $0
                    )
                }
            }
        }
    }

    func makeHeader() -> ProfileHeaderView {
        let userStore = context.userStore
        // Tab 1 is My Lists
        let openMyLists: () -> Void = { [weak self] in self?.tabBarController?.selectedIndex = 1 }
        return ProfileHeaderView(
            user: user,
            followerCount: userStore.followers(of: user.id).count,
            followingCount: userStore.following(of: user.id).count,
            rankedCount: rankings.count,
            onOpenBeen: isCurrentUser ? openMyLists : nil
        )
    }

    func applySnapshot(_ items: [FeedItem]) {
        itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let allItems = [Item.header, .stats] + items.map { Item.visit($0.id) }

        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        snapshot.appendSections([0])
        snapshot.appendItems(allItems)
        // Counts and scores shift as lists change, so redraw everything that stayed
        let previousItems = Set(dataSource.snapshot().itemIdentifiers)
        snapshot.reconfigureItems(allItems.filter(previousItems.contains))

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        if case .visit = dataSource.itemIdentifier(for: indexPath) { true } else { false }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .visit(let id) = dataSource.itemIdentifier(for: indexPath),
              let item = itemsByID[id] else { return }
        showPlace(Place(item.ranking.ranking), context: context)
    }

}

#Preview {
    UINavigationController(rootViewController: ProfileViewController(
        user: SampleData.users.currentUser
    ))
}
