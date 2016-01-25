//
//  DismissSegue.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 25-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import Foundation
import UIKit

@objc(DismissSegue) // without this the segue class will not be found (has to do with the swift compiler name mangling)
class DismissSegue : UIStoryboardSegue {
    override func perform() {
        
        let source = self.sourceViewController
        
        source.dismissViewControllerAnimated(true, completion: nil)
        
    }
}