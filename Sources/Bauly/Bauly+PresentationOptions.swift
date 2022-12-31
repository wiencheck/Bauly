//
//  File.swift
//  
//
//  Created by Adam Wienconek on 28/11/2022.
//

import Foundation
import UIKit

public extension Bauly {
    
    struct PresentationOptions: Sendable {
        
        /// Space between banner and safe area limits.
        public var topPadding: CGFloat
        
        /// Duration of the presentation / dismissal animation (in seconds).
        public var animationDuration: TimeInterval
        
        /// Time after banner disappears from the screen (in seconds).
        ///
        /// If set to zero the banner will stay on the screen until it is manually dismissed.
        public var dismissAfter: TimeInterval
        
        /// Delay for the animation to start.
        public var animationDelay: TimeInterval
        
        /// Indicates whether banner will wait for its turn in the queue
        /// or will be displayed immediately.
        ///
        /// If set to `true` banner will be displayed immediately before
        /// other banners from the queue are presented.
        ///
        /// Defaults to `false`.
        public var presentImmediately: Bool
        
        /// Window scene used for displaying the banner.
        ///
        /// If `nil` is passed banner will be displayed in the first active window scene.
        public var windowScene: UIWindowScene?
        
        /// Style of haptic feedback which occurs when banner is presented.
        ///
        /// If set to `nil` no haptic feedback will be generated when presenting the banner.
        ///
        /// Defaults to `.medium`
        public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?
        
        /// Indicates whether tapping on the banner should dismiss it.
        ///
        /// Defaults to `true`
        public var isDismissedByTap: Bool
        
        /// Indicates whether banner can be dragged.
        ///
        /// If set to `true` banner can be dismissed by dragging it out of the screen
        ///
        /// Defaults to `true`
        public var supportsDragging: Bool
        
        public init(topPadding: CGFloat = 2,
                    animationDuration: TimeInterval = 0.58,
                    dismissAfter: TimeInterval = 3.8,
                    animationDelay: TimeInterval = 0.05,
                    presentImmediately: Bool = false,
                    windowScene: UIWindowScene? = nil,
                    feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .medium,
                    isDismissedByTap: Bool = true,
                    supportsDragging: Bool = true) {
            self.topPadding = topPadding
            self.animationDuration = animationDuration
            self.dismissAfter = dismissAfter
            self.animationDelay = animationDelay
            self.presentImmediately = presentImmediately
            self.windowScene = windowScene
            self.feedbackStyle = feedbackStyle
            self.isDismissedByTap = isDismissedByTap
            self.supportsDragging = supportsDragging
        }
    }
    
}
