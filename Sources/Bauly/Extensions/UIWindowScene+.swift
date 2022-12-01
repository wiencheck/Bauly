//
//  UIWindowScene+.swift
//  
//
//  Created by Adam Wienconek on 28/11/2022.
//

import Foundation
import UIKit

extension UIWindowScene {
    
    @available(iOS, obsoleted: 15.0, message: "This property is available natively from iOS 15.0")
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
    
}
