//
//  File.swift
//  
//
//  Created by Adam Wienconek on 28/11/2022.
//

import Foundation
import UIKit

extension NSLayoutConstraint {
    
    func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
    
}
