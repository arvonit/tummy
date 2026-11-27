//
//  PhotoStripView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// A sideways-scrolling row of square photo thumbnails
struct PhotoStripView: View {
    let photos: [Data]
    var side: CGFloat = 160

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos.indices, id: \.self) { index in
                    if let image = UIImage(data: photos[index]) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                }
            }
        }
    }
}
