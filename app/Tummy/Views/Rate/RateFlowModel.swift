//
//  RateFlowModel.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import PhotosUI
import SwiftUI

/// State for one pass through the rate flow: the details sheet, the comparisons, and the result
@Observable
class RateFlowModel {

    enum Step: Hashable {
        case compare
        case result
    }

    let place: Place
    /// Your current ranking of the place, if you've been before
    let existing: ScoredRanking?
    let context: AppContext

    var category: PlaceCategory
    var bucket: Bucket?
    var reRank = false
    var notes = ""
    var dishes: [String] = []
    var photos: [Data] = []
    var visitDate = Calendar.current.startOfDay(for: .now)
    var path: [Step] = []

    /// Your other places in the chosen list, worst first, so an index is a position
    private(set) var candidates: [Ranking] = []
    private(set) var insertion = BinaryInsertion(count: 0)

    init(summary: PlaceSummary, context: AppContext) {
        place = summary.place
        existing = summary.ranking
        category = summary.category
        bucket = summary.ranking?.bucket
        self.context = context
    }

    /// A revisit that keeps the same list. Only then is skipping the comparisons allowed.
    var isSameList: Bool {
        existing?.category == category && existing?.bucket == bucket
    }

    /// The place to compare against, or nil once the position is found
    var comparisonPlace: Ranking? {
        insertion.isDone ? nil : candidates[insertion.midpoint]
    }

    /// Your score and rank in the list after saving
    var result: (ranking: ScoredRanking, rank: Int, count: Int)? {
        let list = context.myScoredRankings.filter { $0.category == category }
        guard let index = list.firstIndex(where: { $0.restaurant.mapItemID == place.id })
        else { return nil }
        return (list[index], index + 1, list.count)
    }

    /// Rank on the details sheet
    func confirmDetails() async {
        guard let bucket else { return }
        if isSameList && !reRank {
            await addVisit()
            return
        }

        candidates = context.rankingStore.rankings
            .filter {
                $0.userID == context.currentUserID && $0.category == category
                    && $0.bucket == bucket && $0.restaurant.mapItemID != place.id
            }
            .sorted { $0.position < $1.position }
        insertion = BinaryInsertion(count: candidates.count)

        if insertion.isDone {
            await rank()
        } else {
            path.append(.compare)
        }
    }

    func answer(newIsBetter: Bool) async {
        insertion.answer(newIsBetter: newIsBetter)
        if insertion.isDone { await rank() }
    }

    func skip() async {
        insertion.skip()
        await rank()
    }

    func undo() {
        insertion.undo()
    }

    /// Replaces the photos with the picker's current selection, downscaled for upload
    func loadPhotos(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let downscaled = Self.downscaled(data) {
                loaded.append(downscaled)
            }
        }
        photos = loaded
    }

    private func rank() async {
        guard let bucket else { return }
        // Reuse the restaurant if anyone has ranked it, so everyone's rankings share it
        let earlier = context.rankingStore.rankings.first { $0.restaurant.mapItemID == place.id }
        let restaurant = earlier?.restaurant ?? Restaurant(place)
        do {
            try await context.rankingStore.rank(
                restaurant,
                category: category,
                bucket: bucket,
                at: insertion.position,
                by: context.currentUserID,
                visit: makeVisit(rankingID: UUID())
            )
            path.append(.result)
        } catch {
            print("Failed to save ranking: \(error)")
        }
    }

    private func addVisit() async {
        guard let existing else { return }
        do {
            try await context.rankingStore.addVisit(makeVisit(rankingID: existing.id))
            path.append(.result)
        } catch {
            print("Failed to save visit: \(error)")
        }
    }

    private func makeVisit(rankingID: Ranking.ID) -> Visit {
        Visit(
            id: UUID(),
            rankingID: rankingID,
            date: visitDate,
            createdAt: .now,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dishes: dishes,
            photos: photos
        )
    }

    /// Fits the photo inside 1600 points and re-encodes it as JPEG
    private static func downscaled(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, 1600 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return image.preparingThumbnail(of: size)?.jpegData(compressionQuality: 0.8)
    }

}
