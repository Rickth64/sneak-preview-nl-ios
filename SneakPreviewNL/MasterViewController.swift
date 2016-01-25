//
//  MasterViewController.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 23-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Locksmith

class MasterViewController: UITableViewController, GADInterstitialDelegate {

    private var dataModel: SneakDataModel!
    private let pendingOperations = PendingOperations()
    private let interstitial = GADInterstitial(adUnitID: "ca-app-pub-6550777095004438/4155970709")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.dataModel = SneakDataModel()
        
        self.dataModel.getSneaksFromServerWithSuccess({ () -> Void in
            self.tableView.reloadData()
            }, failure: { () -> Void in
                let alertView = UIAlertView(title: "Oeps...", message: "Er ging iets mis tijdens het ophalen van de sneaks. Probeer het later nogmaals.", delegate: nil, cancelButtonTitle: "OK")
                alertView.show()
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self.tableView, selector: "reloadData", name: kIAPAcquiredNotification, object: nil)
        
        self.interstitial.delegate = self
        let request = GADRequest()
        let keychainData = Locksmith.loadDataForUserAccount(kIAPKeychainUserAccount, inService: kIAPKeychainService)
        if let actualData = keychainData {
            if (actualData[kIAPKeychainKey] as! String != kIAPKeychainValueTrue) {
                self.interstitial.loadRequest(request)
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            if segue.identifier == "showDetail" {
                let sneak: SneakMovie = self.dataModel[indexPath.section].sneakMovies[indexPath.row]
                (segue.destinationViewController as! DetailViewController).sneakMovie = sneak
                (segue.destinationViewController as! DetailViewController).title = "Week \(self.dataModel[indexPath.section].number), \(self.dataModel[indexPath.section].year)"
            } else if segue.identifier == "showUpgrade" {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.dataModel.weekCount > 0 {
            self.tableView.backgroundView = nil
            return self.dataModel.weekCount
        } else {
            // Display a message when the table is empty
            
            let messageLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            
            messageLabel.text = "Er zijn momenteel geen sneaks om weer te geven. Trek omlaag om te vernieuwen."
            messageLabel.textColor = UIColor.whiteColor()
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .Center
            messageLabel.font = UIFont.systemFontOfSize(20)
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel;
            //self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataModel[section].sneakMovies.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 125.0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataModel[section].description
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25.0
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView //recast your view as a UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0) //make the background color light blue
        header.textLabel?.textColor = UIColor.whiteColor() //make the text white
        header.textLabel?.textAlignment = NSTextAlignment.Center
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let sneak = self.dataModel[indexPath.section].sneakMovies[indexPath.row]
        
        var isUpgraded = false
    
        let keychainData = Locksmith.loadDataForUserAccount("SPNL", inService: "SPNLService")
        if let actualData = keychainData {
            if (actualData["upgraded"] as! String? == "YeSsSsS") {
                isUpgraded = true
            }
        }
        
        if sneak.isConfirmed! || isUpgraded {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! SneakMovieTableViewCell
            
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.detailTextLabel?.textColor = UIColor.whiteColor()
            
            if cell.accessoryView == nil {
                let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
                cell.accessoryView = indicator
            }
            let indicator = cell.accessoryView as! UIActivityIndicatorView
            
            if cell.backgroundView == nil {
                let iv = UIImageView()
                iv.tag = 1234
                iv.backgroundColor = UIColor.clearColor()
                iv.opaque = false
                iv.contentMode = UIViewContentMode.ScaleAspectFill
                iv.clipsToBounds = true
                let vev = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
                vev.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)
                iv.addSubview(vev)
                
                cell.backgroundView = iv
            }
            
            let iv = cell.backgroundView?.viewWithTag(1234) as! UIImageView
            
            cell.backgroundColor = UIColor.clearColor()
            
            cell.textLabel?.text = sneak.title
            
            if let posterImage = sneak.posterImage {
                cell.imageView?.image = posterImage
                iv.image = posterImage
            } else {
                cell.imageView?.image = UIImage(named: "PosterPlaceholder")
                iv.image = nil
            }
            
            switch (sneak.state) {
            case .New:
                indicator.startAnimating()
                cell.textLabel?.text = "Titel ophalen..."
                cell.detailTextLabel?.text = "Filminformatie ophalen...(1/4)"
                startInfoDownloadForSneakMovie(sneak, indexPath: indexPath)
            case .InfoDownloaded:
                indicator.startAnimating()
                cell.detailTextLabel?.text = "Poster ophalen...(2/4)"
                startPosterDownloadForSneakMovie(sneak, indexPath: indexPath)
            case .PosterDownloaded:
                indicator.startAnimating()
                cell.detailTextLabel?.text = "Backdrop ophalen...(3/4)"
                startBackdropDownloadForSneakMovie(sneak, indexPath: indexPath)
            case .BackdropDownloaded:
                indicator.startAnimating()
                cell.detailTextLabel?.text = "Trailer ophalen...(4/4)"
                startTrailerDownloadForSneakMovie(sneak, indexPath: indexPath)
            case .TrailerDownloaded:
                indicator.stopAnimating()
                if sneak.isConfirmed! {
                    cell.detailTextLabel?.text = sneak.tagline //"If you never face your enemy, how can you face yourself."
                } else {
                    cell.detailTextLabel?.text = "NIET BEVESTIGD"
                }
                cell.accessoryView = nil
                cell.accessoryType = .DisclosureIndicator
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("CellUpgrade", forIndexPath: indexPath)
            
            return cell
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        //1
        suspendAllOperations()
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 2
        if !decelerate {
            loadSneaksForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // 3
        loadSneaksForOnscreenCells()
        resumeAllOperations()
    }
    
    @IBAction func refreshControlPulled(sender: UIRefreshControl) {
        self.dataModel.getSneaksFromServerWithSuccess({ () -> Void in
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            }, failure: { () -> Void in
                let alertView = UIAlertView(title: "Oeps...", message: "Er ging iets mis tijdens het ophalen van de sneaks. Probeer het later nogmaals.", delegate: nil, cancelButtonTitle: "OK")
                alertView.show()
        })
    }
    
    // MARK: - TheMovieDB API call operations
    
    func suspendAllOperations () {
        pendingOperations.infoDownloadQueue.suspended = true
        pendingOperations.posterDownloadQueue.suspended = true
        pendingOperations.backdropDownloadQueue.suspended = true
        pendingOperations.trailerDownloadQueue.suspended = true
    }
    
    func resumeAllOperations () {
        pendingOperations.infoDownloadQueue.suspended = false
        pendingOperations.posterDownloadQueue.suspended = false
        pendingOperations.backdropDownloadQueue.suspended = false
        pendingOperations.trailerDownloadQueue.suspended = false
    }
    
    func loadSneaksForOnscreenCells () {
        if let pathsArray = tableView.indexPathsForVisibleRows {
            //2
            var allPendingOperations = Set(pendingOperations.infoDownloadsInProgress.keys)
            allPendingOperations.unionInPlace(pendingOperations.posterDownloadsInProgress.keys)
            allPendingOperations.unionInPlace(pendingOperations.backdropDownloadsInProgress.keys)
            allPendingOperations.unionInPlace(pendingOperations.trailerDownloadsInProgress.keys)
            
            //3
            let visiblePaths = Set(pathsArray)
            let toBeCancelled = allPendingOperations.subtract(visiblePaths)
            
            //4
            let toBeStarted = visiblePaths.subtract(allPendingOperations)
            
            // 5
            for indexPath in toBeCancelled {
                if let pendingInfoDownload = pendingOperations.infoDownloadsInProgress[indexPath] {
                    pendingInfoDownload.cancel()
                }
                pendingOperations.infoDownloadsInProgress.removeValueForKey(indexPath)
                
                if let pendingPosterDownload = pendingOperations.posterDownloadsInProgress[indexPath] {
                    pendingPosterDownload.cancel()
                }
                pendingOperations.posterDownloadsInProgress.removeValueForKey(indexPath)
                
                if let pendingBackdropDownload = pendingOperations.backdropDownloadsInProgress[indexPath] {
                    pendingBackdropDownload.cancel()
                }
                pendingOperations.backdropDownloadsInProgress.removeValueForKey(indexPath)
                
                if let pendingTrailerDownload = pendingOperations.trailerDownloadsInProgress[indexPath] {
                    pendingTrailerDownload.cancel()
                }
                pendingOperations.trailerDownloadsInProgress.removeValueForKey(indexPath)
            }
            
            // 6
            for indexPath in toBeStarted {
                let recordToProcess = self.dataModel[indexPath.section].sneakMovies[indexPath.row]
                startOperationsForSneakMovie(recordToProcess, indexPath: indexPath)
            }
        }
    }
    
    func startOperationsForSneakMovie(sneakMovie: SneakMovie, indexPath: NSIndexPath) {
        switch (sneakMovie.state) {
        case .New:
            startInfoDownloadForSneakMovie(sneakMovie, indexPath: indexPath)
        case .InfoDownloaded:
            startPosterDownloadForSneakMovie(sneakMovie, indexPath: indexPath)
        case .PosterDownloaded:
            startBackdropDownloadForSneakMovie(sneakMovie, indexPath: indexPath)
        case .BackdropDownloaded:
            startTrailerDownloadForSneakMovie(sneakMovie, indexPath: indexPath)
        default:
            return
        }
    }
    
    func startInfoDownloadForSneakMovie(sneakMovie: SneakMovie, indexPath: NSIndexPath) {
        
        if let _ = pendingOperations.infoDownloadsInProgress[indexPath] {
            return
        }
        
        let infoDownloader = InfoDownloader(sneakMovie: sneakMovie)
        
        infoDownloader.completionBlock = {
            if infoDownloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.infoDownloadsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                NSNotificationCenter.defaultCenter().postNotificationName("infoDownloaded-\(sneakMovie.tmdbID)", object: nil)
            })
        }
        
        pendingOperations.infoDownloadsInProgress[indexPath] = infoDownloader
        pendingOperations.infoDownloadQueue.addOperation(infoDownloader)
    }
    
    func startPosterDownloadForSneakMovie(sneakMovie: SneakMovie, indexPath: NSIndexPath) {
        if let _ = pendingOperations.posterDownloadsInProgress[indexPath] {
            return
        }
        
        let posterDownloader = PosterDownloader(sneakMovie: sneakMovie)
        
        posterDownloader.completionBlock = {
            if posterDownloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.posterDownloadsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                NSNotificationCenter.defaultCenter().postNotificationName("posterDownloaded-\(sneakMovie.tmdbID)", object: nil)
            })
        }
        
        pendingOperations.posterDownloadsInProgress[indexPath] = posterDownloader
        pendingOperations.posterDownloadQueue.addOperation(posterDownloader)
    }
    
    func startBackdropDownloadForSneakMovie(sneakMovie: SneakMovie, indexPath: NSIndexPath) {
        if let _ = pendingOperations.backdropDownloadsInProgress[indexPath] {
            return
        }
        
        let backdropDownloader = BackdropDownloader(sneakMovie: sneakMovie)
        
        backdropDownloader.completionBlock = {
            if backdropDownloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.backdropDownloadsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                NSNotificationCenter.defaultCenter().postNotificationName("backdropDownloaded-\(sneakMovie.tmdbID)", object: nil)
            })
        }
        
        pendingOperations.backdropDownloadsInProgress[indexPath] = backdropDownloader
        pendingOperations.backdropDownloadQueue.addOperation(backdropDownloader)
    }
    
    func startTrailerDownloadForSneakMovie(sneakMovie: SneakMovie, indexPath: NSIndexPath) {
        if let _ = pendingOperations.trailerDownloadsInProgress[indexPath] {
            return
        }
        
        let trailerDownloader = TrailerDownloader(sneakMovie: sneakMovie)
        
        trailerDownloader.completionBlock = {
            if trailerDownloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.trailerDownloadsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                NSNotificationCenter.defaultCenter().postNotificationName("trailerDownloaded-\(sneakMovie.tmdbID)", object: nil)
            })
        }
        
        pendingOperations.trailerDownloadsInProgress[indexPath] = trailerDownloader
        pendingOperations.trailerDownloadQueue.addOperation(trailerDownloader)
    }
    
    // MARK: - Google Ads Interstitial
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        self.interstitial.presentFromRootViewController(self)
    }


}

