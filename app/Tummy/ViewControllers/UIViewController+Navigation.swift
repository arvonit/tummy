//
//  UIViewController+Navigation.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI
import UIKit

/// Screens that every tab can reach, so the map, lists, and feed open them the same way
extension UIViewController {

    func showPlace(_ place: Place, context: AppContext) {
        let placeView = UIHostingController(rootView: PlaceView(
            place: place,
            context: context,
            onRank: { [weak self] in self?.presentRateFlow(for: $0, context: context) }
        ))
        placeView.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(placeView, animated: true)
    }

    func showProfile(of user: User, context: AppContext) {
        let profile = ProfileViewController(user: user, context: context)
        navigationController?.pushViewController(profile, animated: true)
    }

    func presentRateFlow(for summary: PlaceSummary, context: AppContext) {
        let model = RateFlowModel(summary: summary, context: context)
        let rateFlow = UIHostingController(rootView: RateFlowView(
            model: model,
            onClose: { [weak self] in self?.dismiss(animated: true) }
        ))
        present(rateFlow, animated: true)
    }

}
