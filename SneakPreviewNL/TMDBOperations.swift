//
//  TMDBOperations.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 23-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import SwiftyJSON

class PendingOperations {
    lazy var infoDownloadsInProgress = [NSIndexPath:NSOperation]()
    lazy var infoDownloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Info download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
        }()
    
    lazy var posterDownloadsInProgress = [NSIndexPath:NSOperation]()
    lazy var posterDownloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Poster download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
        }()
    
    lazy var backdropDownloadsInProgress = [NSIndexPath:NSOperation]()
    lazy var backdropDownloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Backdrop download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
        }()
    
    lazy var trailerDownloadsInProgress = [NSIndexPath:NSOperation]()
    lazy var trailerDownloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Trailer download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
        }()
}

class InfoDownloader: NSOperation {
    let sneakMovie: SneakMovie
    
    private let TMDB_API_BASE_URL = "http://api.themoviedb.org/3/"
    private let TMDB_API_KEY = "bc83d3892148454778d8f28f3e722378"
    
    init(sneakMovie: SneakMovie) {
        self.sneakMovie = sneakMovie
    }
    
    override func main() {
        if self.cancelled {
            return
        }
        
        let url = NSURL(string: "\(TMDB_API_BASE_URL)movie/\(sneakMovie.tmdbID)?api_key=\(TMDB_API_KEY)&language=nl")!
        let data = NSData(contentsOfURL: url)
        
        if self.cancelled {
            return
        }
        
        if let infoData = data {
            
            let json = JSON(data: infoData)
            
            self.sneakMovie.title = json["title"].string
            self.sneakMovie.overview = json["overview"].string
            self.sneakMovie.runtime = json["runtime"].number?.integerValue
            self.sneakMovie.posterPath = json["poster_path"].string
            self.sneakMovie.backdropPath = json["backdrop_path"].string
            self.sneakMovie.imdbID = json["imdb_id"].string
            
            self.sneakMovie.tagline = json["tagline"].string
        }
        
        self.sneakMovie.state = SneakMovieState.InfoDownloaded
        
    }
}

class PosterDownloader: NSOperation {
    let sneakMovie: SneakMovie
    
    init(sneakMovie: SneakMovie) {
        self.sneakMovie = sneakMovie
    }
    
    override func main() {
        if self.cancelled {
            return
        }
        
        if let posterPath = sneakMovie.posterPath {
            
            let imageURL = NSURL(string: "http://image.tmdb.org/t/p/w185\(posterPath)")!
            
            let data = NSData(contentsOfURL: imageURL)
            
            if self.cancelled {
                return
            }
            
            if let imageData = data {
                
                let image = UIImage(data: imageData)
                self.sneakMovie.posterImage = image
            }
        }
        self.sneakMovie.state = .PosterDownloaded
    }
}

class BackdropDownloader: NSOperation {
    let sneakMovie: SneakMovie
    
    init(sneakMovie: SneakMovie) {
        self.sneakMovie = sneakMovie
    }
    
    override func main() {
        if self.cancelled {
            return
        }
        
        if let backdropPath = sneakMovie.backdropPath {
            
            let imageURL = NSURL(string: "http://image.tmdb.org/t/p/w780\(backdropPath)")!
            
            let data = NSData(contentsOfURL: imageURL)
            
            if self.cancelled {
                return
            }
            
            if let imageData = data {
                
                let image = UIImage(data: imageData)
                self.sneakMovie.backdropImage = image
            }
        }
        self.sneakMovie.state = .BackdropDownloaded
    }
}

class TrailerDownloader: NSOperation {
    
    private let TMDB_API_BASE_URL = "http://api.themoviedb.org/3/"
    private let TMDB_API_KEY = "bc83d3892148454778d8f28f3e722378"
    
    let sneakMovie: SneakMovie
    
    init(sneakMovie: SneakMovie) {
        self.sneakMovie = sneakMovie
    }
    
    override func main() {
        if self.cancelled {
            return
        }
        
        let url = NSURL(string: "\(TMDB_API_BASE_URL)movie/\(sneakMovie.tmdbID)/trailers?api_key=\(TMDB_API_KEY)")!
        let data = NSData(contentsOfURL: url)
        
        if self.cancelled {
            return
        }
        
        if let trailerData = data {
            
            let json = JSON(data: trailerData)
            
            if let youtubeTrailers = json["youtube"].array {
                
                if (youtubeTrailers.count > 0) {
                    let firstTrailerSource = youtubeTrailers[0]["source"]
                    
                    let trailerURL = NSURL(string: "http://www.youtube.com/watch?v=\(firstTrailerSource)")
                    
                    self.sneakMovie.trailerURL = trailerURL
                }
            }
        }
        
        self.sneakMovie.state = .TrailerDownloaded
    }
}