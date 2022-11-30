//
//  PresentationState.swift
//  
//
//  Created by Adam Wienconek on 28/11/2022.
//

import Foundation

public extension Bauly {
    
    /// Values indicating banner status.
    enum PresentationState: Sendable {
        
        /// State in which banner is just about to be displayed.
        ///
        /// You can use the associated banner value to customize it before it's visible.
        case willPresent(BaulyView)
        
        /// State in which banner is visible on the screen.
        case presented
        
        /// State in which the banner is no longer visible on the screen.
        case dismissed
        
    }
    
}
