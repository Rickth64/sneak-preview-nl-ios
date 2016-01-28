//
//  SneakMovie.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 25-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import Foundation
import UIKit

enum SneakMovieState {
    case New, InfoDownloaded, PosterDownloaded, BackdropDownloaded, TrailerDownloaded
}

class SneakMovie {
    
    let tmdbID: String!
    var title: String?
    var overview: String?
    var imdbID: String?
    var runtime: Int?
    var trailerURL: NSURL?
    var posterPath: String?
    var posterImage: UIImage?
    var backdropPath: String?
    var backdropImage: UIImage?
    let isConfirmed: Bool!
    var state = SneakMovieState.New
    
    var tagline: String?
    
    init(fromTMDB id: String) {
        if (id.hasPrefix("?")) {
            //remove the first character (the question mark)
            self.tmdbID = id.substringFromIndex(id.startIndex.advancedBy(1))
            self.isConfirmed = false
        } else {
            self.tmdbID = id
            self.isConfirmed = true
        }
    }
}