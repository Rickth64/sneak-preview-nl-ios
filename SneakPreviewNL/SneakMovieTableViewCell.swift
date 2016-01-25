//
//  SneakMovieTableViewCell.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 25-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import Foundation
import UIKit

class SneakMovieTableViewCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView?.frame = CGRectMake(0, 0, self.frame.size.height / 1.5, self.frame.size.height)
        
        var textLabelFrame = self.textLabel?.frame
        textLabelFrame?.origin.x = self.imageView!.frame.origin.x + self.imageView!.frame.size.width + 25
        self.textLabel?.frame = textLabelFrame!
        
        var detailTextLabelFrame = self.detailTextLabel?.frame
        detailTextLabelFrame?.origin.x = self.textLabel!.frame.origin.x
        self.detailTextLabel?.frame = detailTextLabelFrame!
    }
    
}