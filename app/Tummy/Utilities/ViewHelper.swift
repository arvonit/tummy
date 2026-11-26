//
//  ViewHelper.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import SwiftUI
import UIKit

enum ViewHelper {

    static func makeRankingCell() -> UICollectionView.CellRegistration<
        UICollectionViewListCell, RankingRow
    > {
        UICollectionView.CellRegistration<UICollectionViewListCell, RankingRow> {
            cell, indexPath, row in
            cell.contentConfiguration = UIHostingConfiguration {
                RankingCellView(row: row)
            }
        }
    }

}
