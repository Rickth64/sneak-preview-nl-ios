//
//  SneakDataModel.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 25-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import Foundation
import Alamofire

class SneakDataModel {
    
    private var dictionary: [NSDate: SneakWeek]!
    private var sortedKeys: [NSDate]!
    
    var weekCount: Int {
        return self.dictionary.keys.count
    }
    
    init() {
        self.dictionary = [:]
        self.sortedKeys = []
    }
    
    func getSneaksFromServerWithSuccess(success: (() -> Void), failure: (() -> Void)) {
        
        let urlreq = NSURLRequest(URL: NSURL(string: "http://www.thijssenwings.com/SneakPreviewNL/sneakList.plist")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 20)
        
        Alamofire.request(urlreq).responsePropertyList { (response) -> Void in
            if (response.result.error == nil) {
                self.dictionary = [:]
                self.sortedKeys = []
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
                dateFormatter.dateFormat = "ddMMyyyy"
                
                if let sneakList: AnyObject = response.result.value {
                    for (dateKey, sneakIds) in sneakList as! [String: [String]] {
                        
                        let dateKeyAsNSDate = dateFormatter.dateFromString(dateKey)
                        
                        var sneakMoviesForWeek: [SneakMovie] = []
                        
                        for (sneakId) in sneakIds {
                            sneakMoviesForWeek.append(SneakMovie(fromTMDB: sneakId))
                        }
                        
                        self.dictionary[dateKeyAsNSDate!] = SneakWeek(sneaks: sneakMoviesForWeek, date:dateKeyAsNSDate!)
                        self.sortedKeys = self.dictionary.keys.sort { (firstDate, secondDate) -> Bool in
                            return firstDate.compare(secondDate) == NSComparisonResult.OrderedDescending
                        }
                    }
                    
                    success()
                }
            } else {
                failure()
            }
        }
            
    }
    
    subscript(index: Int) -> SneakWeek {
        return self.dictionary[self.sortedKeys[index]]!
    }
}