//
//  File.swift
//  
//
//  Created by Adam Wienconek on 28/11/2022.
//

import Foundation
import UIKit

extension UIWindowScene {
    
    static var focused: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .filter {
                $0 is UIWindowScene &&
                $0.activationState == .foregroundActive
            }
            .first as? UIWindowScene
    }
    
    @available(iOS, deprecated: 15.0)
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
    
}

//extension UIWindow {
//    
//    static var focused: Self? {
//        UIApplication.shared.connectedScenes
//    }
//    
//}
