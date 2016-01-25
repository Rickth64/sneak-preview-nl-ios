//
//  UpgradeViewController.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 25-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import Foundation
import StoreKit
import Locksmith
import Parse

class UpgradeViewController: UIViewController,/* SKPaymentTransactionObserver,*/ SKProductsRequestDelegate {
    
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var purchaseActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var restoreActivityIndicatorView: UIActivityIndicatorView!
    
    var product: SKProduct?
    var productID = "com.thijssenwings.SneakPreviewNL.AdFree"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "upgradePurchasedOrRestored", name: "upgradePurchaseOrRestoreSuccessful", object: nil)
        
        self.upgradeButton.setTitle("Prijs ophalen...", forState: .Normal)
        self.upgradeButton.enabled = false
        //SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        getProductInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: Set(arrayLiteral: self.productID))
            request.delegate = self
            request.start()
            self.purchaseActivityIndicatorView.startAnimating()
        } else {
            self.upgradeButton.setTitle("Aankoop niet mogelijk", forState: .Normal)
            let alert = UIAlertView(title: "Aankoop niet mogelijk", message: "Schakel 'aankopen vanuit apps' in bij Instellingen->Algemeen->Beperkingen.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        var products = response.products
        
        if products.count != 0 {
            self.product = products[0]
            self.upgradeButton.setTitle("Koop nu voor maar €\(self.product!.price)!", forState: .Normal)
            self.upgradeButton.enabled = true
            self.purchaseActivityIndicatorView.stopAnimating()
        }
        
        let invalidProducts = response.invalidProductIdentifiers
        
        for p in invalidProducts {
            print("Product not found: \(p)")
        }
    }
    
    @IBAction func upgradeTapped(sender: UIButton) {
        self.upgradeButton.enabled = false
        //PFPurchase.buyProduct("com.thijssenwings.SneakPreviewNL.AdFree", block: nil)
        PFPurchase.buyProduct("com.thijssenwings.SneakPreviewNL.AdFree", block: { (error: NSError?) -> Void in
            if (error != nil) {
                let alert = UIAlertView(title: "Aankoop mislukt", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
                self.upgradeButton.enabled = true
                self.purchaseActivityIndicatorView.stopAnimating()
            }
        })
        self.purchaseActivityIndicatorView.startAnimating()
    }
    
    @IBAction func restoreTapped(sender: UIButton) {
        PFPurchase.restore()
        self.restoreActivityIndicatorView.startAnimating()
    }
    
    @IBAction func dismissTapped(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func upgradePurchasedOrRestored() {
        self.purchaseActivityIndicatorView.stopAnimating()
        self.restoreActivityIndicatorView.stopAnimating()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
