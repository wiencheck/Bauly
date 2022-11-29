//
//  File 2.swift
//  
//
//  Created by Adam Wienconek on 29/11/2022.
//

import Foundation
import UIKit.UIFont

extension UIFont {
    
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        return metrics.scaledFont(for: font)
    }
    
}
