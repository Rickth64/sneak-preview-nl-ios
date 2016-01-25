//
//  DetailViewController.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 23-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Locksmith

class DetailViewController: UIViewController, GADBannerViewDelegate {

    @IBOutlet weak var movieTitleLabel: UILabel!
    @IBOutlet weak var movieRuntimeLabel: UILabel!
    @IBOutlet weak var movieTrailerButton: UIButton!
    @IBOutlet weak var movieBackdropImageView: UIImageView!
    @IBOutlet weak var movieOverviewTextView: UITextView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    private let IMDB_TITLE_BASE_URL = "imdb:///title"
    private let IMDB_TITLE_WEB_BASE_URL = "http://www.imdb.com/title"
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var bannerViewLayoutConstraint: NSLayoutConstraint!
    
    
    
    var sneakMovie: SneakMovie? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        
        if let title = self.sneakMovie?.title {
            self.movieTitleLabel?.text = title
        } else {
            self.movieTitleLabel?.text = "Titel ophalen..."
        }
        
        self.movieOverviewTextView?.scrollEnabled = false
        
        if let overview = self.sneakMovie?.overview {
            self.movieOverviewTextView?.text = overview
        } else {
            self.movieOverviewTextView?.text = "Er is momenteel helaas geen Nederlandse omschrijving van deze film beschikbaar. Probeer het later nogmaals."
        }
        
        self.movieOverviewTextView?.scrollEnabled = true
        
        if let _ = self.sneakMovie?.imdbID {
            self.navigationItem.rightBarButtonItem?.enabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
        
        if let runtime = self.sneakMovie?.runtime {
            if (runtime == 0) {
                self.movieRuntimeLabel?.text = "onbekend"
            } else {
                self.movieRuntimeLabel?.text = "\(runtime) minuten"
            }
        } else {
            self.movieRuntimeLabel?.text = "onbekend"
        }
        
        if let _ = self.sneakMovie?.trailerURL {
            self.movieTrailerButton?.titleLabel?.text = "Trailer (YouTube)"
            self.movieTrailerButton?.enabled = true
        } else {
            self.movieTrailerButton?.titleLabel?.text = "geen trailer"
            self.movieTrailerButton?.enabled = false
        }
        
        //
        self.movieBackdropImageView?.image = self.sneakMovie?.backdropImage
        self.backgroundImageView?.image = self.sneakMovie?.backdropImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.bannerView.adUnitID = "ca-app-pub-6550777095004438/5557468709"
        self.bannerView.rootViewController = self
        self.bannerView.delegate = self
        
        let imdbButton = UIButton(type: UIButtonType.System)
        imdbButton.frame = CGRectMake(0, 0, 60, 30)
        imdbButton.setImage(UIImage(named: "ImdbLogo"), forState: UIControlState.Normal)
        imdbButton.addTarget(self, action: "openInIMDB", forControlEvents: UIControlEvents.TouchUpInside)
        
        let imdbButtonItem = UIBarButtonItem(customView: imdbButton)
        
        self.navigationItem.rightBarButtonItem = imdbButtonItem
        
        let verticalMotionEffect: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -50
        verticalMotionEffect.maximumRelativeValue = 50
        
        self.backgroundImageView?.addMotionEffect(verticalMotionEffect)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sneakMovieUpdated", name: "infoDownloaded-\(self.sneakMovie!.tmdbID)", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sneakMovieUpdated", name: "backdropDownloaded-\(self.sneakMovie!.tmdbID)", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sneakMovieUpdated", name: "trailerDownloaded-\(self.sneakMovie!.tmdbID)", object: nil)
        
        self.movieOverviewTextView?.editable = false
        self.movieOverviewTextView?.selectable = false
        
        self.configureView()
        
        self.movieOverviewTextView?.layoutIfNeeded()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let keychainData = Locksmith.loadDataForUserAccount("SPNL", inService: "SPNLService")
        if let actualData = keychainData {
            if (actualData["upgraded"] as! String? != "YeSsSsS") {
                let request = GADRequest()
                self.bannerView.loadRequest(request)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openInIMDB() {
        if let sneak = self.sneakMovie {
            var baseURL: String
            
            if (UIApplication.sharedApplication().canOpenURL(NSURL(string: IMDB_TITLE_BASE_URL)!)) {
                baseURL = IMDB_TITLE_BASE_URL
            } else {
                baseURL = IMDB_TITLE_WEB_BASE_URL
            }
            
            UIApplication.sharedApplication().openURL(NSURL(string: "\(baseURL)/\(sneak.imdbID!)/")!)
        }
        
        
    }
    
    @IBAction func openInYouTube() {
        if let url = self.sneakMovie?.trailerURL {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    func sneakMovieUpdated() {
        self.configureView()
    }
    
    override func viewDidLayoutSubviews() {
        self.movieOverviewTextView.contentOffset = CGPointZero
    }
    
    
    func adViewDidReceiveAd(view: GADBannerView!) {
        self.bannerViewLayoutConstraint.constant = 0
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func adView(view: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        self.bannerViewLayoutConstraint.constant = -50
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}

