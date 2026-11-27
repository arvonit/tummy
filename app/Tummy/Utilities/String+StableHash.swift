//
//  String+StableHash.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import Foundation

nonisolated extension String {
    /// FNV-1a, because Swift's `hashValue` changes on every launch
    var stableHash: UInt64 {
        utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
