//
//  SneakWeek.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 25-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import Foundation

class SneakWeek {
    
    var sneakMovies: [SneakMovie]!
    var number: Int!
    var year: Int!
    var description: String!
    
    init(sneaks: [SneakMovie], date: NSDate) {
        self.sneakMovies = sneaks
        
        // The end date, used for the week number, is 6 days from the start date.
        let sneakWeekEndDate = NSDate(timeInterval: 3600*24*6, sinceDate: date)
        
        let calendar = NSCalendar.currentCalendar()
        self.number = calendar.component(NSCalendarUnit.WeekOfYear, fromDate: sneakWeekEndDate)
        self.year = calendar.component(NSCalendarUnit.Year, fromDate: sneakWeekEndDate)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        self.description = "Week \(self.number) (\(dateFormatter.stringFromDate(date)) - \(dateFormatter.stringFromDate(sneakWeekEndDate)))"
    }
}
