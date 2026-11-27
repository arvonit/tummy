//
//  UserStore.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import Foundation
import Observation

/// Where screens get people and follows from
protocol UserStore: AnyObject, Observable {
    var currentUser: User { get }
    var users: [User] { get }
    var follows: [Follow] { get }
}

extension UserStore {

    func followers(of id: User.ID) -> [User.ID] {
        follows.filter { $0.followeeID == id }.map(\.followerID)
    }

    func following(of id: User.ID) -> [User.ID] {
        follows.filter { $0.followerID == id }.map(\.followeeID)
    }

}

/// Keeps the sample users in memory. Following and unfollowing come with the backend.
@Observable
class SampleUserStore: UserStore {
    private(set) var currentUser = SampleData.users.currentUser
    private(set) var users = SampleData.users.all
    private(set) var follows = SampleData.users.follows
}
