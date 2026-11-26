//
//  MyListsViewController.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import SwiftUI
import UIKit

class MyListsViewController: UIViewController, UICollectionViewDelegate {

    let store: RankingStore

    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Int, Ranking.ID>!
    var categoryChips: UIHostingController<CategoryChipsView>!

    var scoredRankings: [ScoredRanking] = []
    var rowsByID: [Ranking.ID: RankingRow] = [:]
    /// nil shows every category
    var selectedCategory: PlaceCategory?

    init(store: RankingStore = SampleRankingStore()) {
        self.store = store
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
        Task { await loadRankings() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Grow the top safe area by the chips' height so they act as the nav bar's bottom edge:
        // the list starts below them and the bar's edge effect extends behind them
        let chipsHeight = categoryChips.view.frame.height
        if additionalSafeAreaInsets.top != chipsHeight {
            additionalSafeAreaInsets.top = chipsHeight
        }
    }

    func configViewController() {
        title = "My Lists"
        view.backgroundColor = .systemBackground
        // Big title at the top that shrinks into the bar when scrolling
        navigationController?.navigationBar.prefersLargeTitles = true

        categoryChips = UIHostingController(rootView: CategoryChipsView { [weak self] category in
            self?.selectedCategory = category
            self?.applySnapshot()
        })
        // Size the hosted view to the chips' natural height
        categoryChips.sizingOptions = .intrinsicContentSize
        // The chips live inside the space they add to the safe area, so they must ignore safe
        // areas themselves or they'd keep pushing their own content down
        categoryChips.safeAreaRegions = []
        categoryChips.view.backgroundColor = .clear
        categoryChips.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(categoryChips)
        view.addSubview(categoryChips.view)
        categoryChips.didMove(toParent: self)

        NSLayoutConstraint.activate([
            // Sits just above the safe area, in the space added by additionalSafeAreaInsets
            categoryChips.view.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            categoryChips.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryChips.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func configCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeListLayout())
        collectionView.allowsSelection = false
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        // Behind the chips, so rows scroll underneath the glass. Being the first subview also
        // lets the large title collapse as the list scrolls.
        view.insertSubview(collectionView, at: 0)

        // Extend the bar's scroll edge effect down behind the chips, as a solid bar with a
        // dividing line instead of the default soft fade
        collectionView.topEdgeEffect.style = .hard
        let edgeEffect = UIScrollEdgeElementContainerInteraction()
        edgeEffect.scrollView = collectionView
        edgeEffect.edge = .top
        categoryChips.view.addInteraction(edgeEffect)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func configDataSource() {
        let rankingCell = ViewHelper.makeRankingCell()

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            [weak self] collectionView, indexPath, id in
            guard let row = self?.rowsByID[id] else { return nil }
            return collectionView.dequeueConfiguredReusableCell(
                using: rankingCell,
                for: indexPath,
                item: row
            )
        }
    }

    func makeListLayout() -> UICollectionViewCompositionalLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self, let id = dataSource.itemIdentifier(for: indexPath) else { return nil }
            return UISwipeActionsConfiguration(actions: [makeDeleteSwipeAction(for: id)])
        }
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    func makeDeleteSwipeAction(for id: Ranking.ID) -> UIContextualAction {
        let delete = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completion in
            completion(true)
            Task { await self?.deleteRanking(id) }
        }
        delete.image = UIImage(systemName: "trash.fill")
        return delete
    }

    func loadRankings() async {
        do {
            scoredRankings = ScoreCurve.scored(try await store.rankings())
        } catch {
            print("Failed to load rankings: \(error)")
        }
        applySnapshot()
    }

    func deleteRanking(_ id: Ranking.ID) async {
        do {
            try await store.delete(id)
        } catch {
            print("Failed to delete ranking: \(error)")
        }
        // Reload so every remaining place is rescored on the curve
        await loadRankings()
    }

    func applySnapshot() {
        let rows = visibleRows()
        rowsByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.ranking.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Int, Ranking.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(rows.map(\.ranking.id))

        // IDs don't change when a score or rank does, so ask the rows that stayed to redraw
        let previousIDs = Set(dataSource.snapshot().itemIdentifiers)
        snapshot.reconfigureItems(rows.map(\.ranking.id).filter(previousIDs.contains))

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    /// Rankings in the selected category (or all of them), numbered best first
    func visibleRows() -> [RankingRow] {
        scoredRankings
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .enumerated()
            .map { index, ranking in RankingRow(rank: index + 1, ranking: ranking) }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // How far the list is pulled down past its top (negative while scrolled into the list)
        let topOffset = -collectionView.adjustedContentInset.top
        let pullDistance = topOffset - collectionView.contentOffset.y

        // Hide the bar's edge effect while the list rests at its top. Without this, the effect
        // can stay on after scrolling back up and blur the large title.
        collectionView.topEdgeEffect.isHidden = pullDistance >= 0

        // The large title moves down with the list when it's pulled past the top, so move the
        // chips by the same amount to keep them under the title
        categoryChips.view.transform = CGAffineTransform(translationX: 0, y: max(0, pullDistance))
    }

}

#Preview {
    UINavigationController(rootViewController: MyListsViewController())
}
