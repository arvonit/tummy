//
//  SearchViewController.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import CoreLocation
import SwiftUI
import UIKit

/// Hosts the SwiftUI search map, and handles navigation to the Place screen and the rate flow
class SearchViewController: UIViewController {

    let placeStore: PlaceStore
    let rankingStore: RankingStore
    let locationManager = CLLocationManager()

    init(
        placeStore: PlaceStore = MapKitPlaceStore(),
        rankingStore: RankingStore = SampleRankingStore()
    ) {
        self.placeStore = placeStore
        self.rankingStore = rankingStore
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
            placeStore: placeStore,
            rankingStore: rankingStore,
            locationManager: locationManager,
            onOpen: { [weak self] in self?.openPlace($0) },
            onRank: { [weak self] in self?.rank($0) }
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

    func openPlace(_ summary: PlaceSummary) {
        let place = UIHostingController(rootView: PlaceView(
            summary: summary,
            placeStore: placeStore,
            userLocation: locationManager.location,
            onRank: { [weak self] in self?.rank(summary) }
        ))
        place.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(place, animated: true)
    }

    /// Stands in for the rate flow until it's built
    func rank(_ summary: PlaceSummary) {
        let rateFlow = PlaceholderViewController(title: "Rate flow")
        rateFlow.sheetPresentationController?.detents = [.medium(), .large()]
        present(rateFlow, animated: true)
    }

}

#Preview {
    UINavigationController(rootViewController: SearchViewController())
}
