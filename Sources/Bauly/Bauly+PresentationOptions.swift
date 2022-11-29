//
//  File.swift
//  
//
//  Created by Adam Wienconek on 28/11/2022.
//

import Foundation
import UIKit

public extension Bauly {
    
    struct PresentationOptions {
        
        /// Space between banner and safe area limits.
        public var topPadding: CGFloat
        
        /// Duration of the presentation / dismissal animation (in seconds).
        public var animationDuration: TimeInterval
        
        /// Time after banner disappears from the screen (in seconds).
        public var dismissAfter: TimeInterval
        
        /// Delay for the animation to start.
        public var delay: TimeInterval
        
        /// Boolean indicating whether banner will wait for its turn in the queue
        /// or will be displayed immediately.
        ///
        /// If set to `false` banner will be displayed immediately before
        /// other banners from the queue are presented.
        ///
        /// `true` by default.
        public var waitForDismissal: Bool
        
        /// Window scene used for displaying the banner.
        ///
        /// If `nil` is passed banner will be displayed in the first active window scene.
        public var windowScene: UIWindowScene?
        
        /// Style of haptic feedback which occurs when banner is presented.
        public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
        
        public init(topPadding: CGFloat = 2,
                    animationDuration: TimeInterval = 0.58,
                    dismissAfter: TimeInterval = 3.8,
                    delay: TimeInterval = 0.05,
                    waitForDismissal: Bool = true,
                    windowScene: UIWindowScene? = nil,
                    feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
            self.topPadding = topPadding
            self.animationDuration = animationDuration
            self.dismissAfter = dismissAfter
            self.delay = delay
            self.waitForDismissal = waitForDismissal
            self.windowScene = windowScene
            self.feedbackStyle = feedbackStyle
        }
    }
    
}
