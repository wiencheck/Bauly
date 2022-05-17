//
//  Bauly.swift
//
//  Copyright (c) 2020 Adam Wienconek (https://github.com/wiencheck)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

/**
 Class used for displaying banners with similar look to the native iOS13+ compact banners. Use the `shared` singleton to call appropriate methods.
 */
public final class Bauly {
    /// MARK: Public properties
    
    /// Shared instance.
    public static let shared = Bauly()
    
    /// Margin between banner's and `safeAreaLayoutGuide` top.
    public static var topMargin: CGFloat = 2
    
    // MARK: Private properties

    /// Constraint keeping banner in its initial position (outside of the screen)
    private var initialConstraint: NSLayoutConstraint!
    
    /// Constraint keeping banner in its final position (below top edge of the screen)
    private var finalConstraint: NSLayoutConstraint!
    
    /// Currently displayed banner
    public private(set) weak var currentBanner: BaulyView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }
    
    /// Currently running animator.
    private var runningAnimator: UIViewPropertyAnimator? {
        didSet {
            oldValue?.stopAnimation(true)
        }
    }
    
    /// Internal action performed after banner slides out of the screen.
    private var dismissAction: (() -> Void)?
    
    private var presentAction: (() -> Void)?
    
    private var dismissTimer: Timer?
    
    /// Queue of upcoming banners.
    private let queue = BaulyQueue()
    
    /// Default window to use if none is passed to the methods
    private var defaultWindow: UIWindow? {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
    
    private var applicationStateObserver: Any?

    
    /// Private initializer for shared instance
    private init() {
        applicationStateObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] sender in
            self?.handleAppWillEnterBackgroundNotification(sender)
        }
    }
    
    deinit {
        guard let observer = applicationStateObserver else { return }
        NotificationCenter.default.removeObserver(observer, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: Public methods
    
    /**
     Presents `BaulyView` banner. If there are any banners on the screen, or pending in the queue, the new banner will be displayed last.
     - Parameters:
        - configurationHandler: Configuration handler used to modify `BaulyView` properties, like `text` and `icon` but also `tintColor` and other visual properties directly.
        - duration: Duration of the animation, in seconds.
        - delay: Time after banner disappears, in seconds.
                        Pass `0` to keep it on the screen.
        - window: Window in which the banner will be presented.
                    Uses app's default key window if `nil` is passed.
        - completionHandler: Action performed after banner disappears from the screen.
     */
    public func present(configurationHandler: @escaping (BaulyView) -> Void,
                        duration: TimeInterval = 0.56,
                        dismissAfter delay: TimeInterval = 5,
                        in window: UIWindow? = nil,
                        feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil,
                        pressHandler: (() -> Void)? = nil,
                        completionHandler: (() -> Void)? = nil) {
        
        let snapshot = Snapshot(configurationHandler: configurationHandler,
                                duration: duration,
                                dismissAfter: delay,
                                in: window,
                                feedbackStyle: feedbackStyle,
                                pressHandler: pressHandler,
                                completionHandler: completionHandler)
        
        queue.insert(snapshot: snapshot, afterCurrent: false)
        guard currentBanner == nil else {
            return
        }
        present(snapshot: snapshot)
    }
    
    /**
     Presents `BaulyView` banner and forces it to be displayed immediately.
     - Parameters:
        - configurationHandler: Configuration handler used to modify `BaulyView` properties, like `text` and `icon` but also `tintColor` and other visual properties directly.
        - duration: Duration of the animation, in seconds.
        - delay: Time after banner disappears, in seconds.
                        Pass `0` to keep it on the screen.
        - window: Window in which the banner will be presented.
                    Uses app's default key window if `nil` is passed.
        - completionHandler: Action performed after banner disappears from the screen.
     */
    public func forcePresent(configurationHandler: @escaping (BaulyView) -> Void, duration: TimeInterval = 0.56, dismissAfter delay: TimeInterval = 5, in window: UIWindow? = nil, feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil, pressHandler: (() -> Void)? = nil, completionHandler: (() -> Void)? = nil) {
        
        let snapshot = Snapshot(configurationHandler: configurationHandler,
                                duration: duration,
                                dismissAfter: delay,
                                in: window,
                                feedbackStyle: feedbackStyle,
                                pressHandler: pressHandler,
                                completionHandler: completionHandler)
        queue.insert(snapshot: snapshot, afterCurrent: true)
        
        guard currentBanner == nil else {
            dismiss()
            return
        }
        present(snapshot: snapshot)
    }
    
    /**
     Presents `BaulyView` banner. If there are any banners on the screen, or pending in the queue, the new banner will be displayed last.
     - Parameters:
        - title: Main text of the banner.
        - subtitle: Detail text of the banner.
        - icon: Icon image for the banner. Should be a square image.
        - duration: Duration of the animation, in seconds.
        - delay: Time after banner disappears, in seconds.
                        Pass `0` to keep it on the screen.
        - window: Window in which the banner will be presented.
                    Uses app's default key window if `nil` is passed.
        - completionHandler: Action performed after banner disappears from the screen.
     */
    public func present(title: String, subtitle: String?, icon: UIImage?, duration: TimeInterval = 0.56, dismissAfter delay: TimeInterval = 5, in window: UIWindow? = nil, feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil, pressHandler: (() -> Void)? = nil, completionHandler: (() -> Void)? = nil) {
        
        present(configurationHandler: { view in
            view.title = title
            view.subtitle = subtitle
            view.icon = icon
        }, duration: duration, dismissAfter: delay, in: window, feedbackStyle: feedbackStyle, pressHandler: pressHandler, completionHandler: completionHandler)
    }
    
    /**
     Presents `BaulyView` banner and forces it to be displayed immediately.
     - Parameters:
        - title: Main text of the banner.
        - subtitle: Detail text of the banner.
        - icon: Icon image for the banner. Should be a square image.
        - duration: Duration of the animation, in seconds.
        - delay: Time after banner disappears, in seconds.
                        Pass `0` to keep it on the screen.
        - window: Window in which the banner will be presented.
                    Uses app's default key window if `nil` is passed.
        - completionHandler: Action performed after banner disappears from the screen.
     */
    public func forcePresent(title: String, subtitle: String?, icon: UIImage?, duration: TimeInterval = 0.56, dismissAfter delay: TimeInterval = 5, in window: UIWindow? = nil, feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? = nil, pressHandler: (() -> Void)? = nil, completionHandler: (() -> Void)? = nil) {
        
        forcePresent(configurationHandler: { view in
            view.title = title
            view.subtitle = subtitle
            view.icon = icon
        }, duration: duration, dismissAfter: delay, in: window, feedbackStyle: feedbackStyle, pressHandler: pressHandler, completionHandler: completionHandler)
    }
    
    /**
     Updates the currently displayed banner with given properties. Does nothing if no banner is visible on-screen.
     - Parameters:
        - title: Main text of the banner.
        - subtitle: Detail text of the banner.
        - icon: Icon image for the banner. Should be a square image.
     */
    public func update(title: String, subtitle: String?, icon: UIImage?) {
        
        update(configurationHandler: { view in
            view.title = title
            view.subtitle = subtitle
            view.icon = icon
        })
    }
    
    /**
     Updates the currently displayed banner with given properties. Does nothing if no banner is visible on-screen.
     - Parameters:
        - configurationHandler: Configuration handler used to directly modify `BaulyView` properties, like `text` and `icon`
     */
    public func update(configurationHandler: (BaulyView) -> Void) {
        guard let banner = currentBanner else {
            return
        }
        configurationHandler(banner)
        banner.window?.layoutIfNeeded()
    }
    
    /**
     Dismisses currenly displayed banner, if there is any.
     - Parameters:
        - completionHandler: Handler called after banner slides out of the screen. If no banner was visible, the handler will not be called. Use the
     */
    public func dismiss(completionHandler: (() -> Void)? = nil) {
        guard let view = currentBanner else {
            return
        }
        dismissAction = nil
        let dismissAnimator = self.dismissAnimator { [weak self, weak view] in
            if let view = view {
                self?.clean(after: view)
            }
            completionHandler?()
        }
        dismissAnimator.startAnimation()
        runningAnimator = dismissAnimator
    }
    
    // MARK: Private methods
    
    /**
     Presents banner configured with given snapshot.
     - Parameters:
        - snapshot: Configuration of the new banner.
     */
    private func present(snapshot: Snapshot) {
        let view = BaulyView()
        view.identifier = snapshot.identifier
        
        snapshot.configurationHandler?(view)
        view.pressHandler = { [weak self, weak snapshot] in
            self?.dismiss()
            snapshot?.pressHandler?()
        }
        
        guard let _window = snapshot.window ?? defaultWindow else {
            return
        }
        
        _window.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        initialConstraint = view.bottomAnchor.constraint(equalTo: _window.topAnchor)
        initialConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            initialConstraint,
            view.leftAnchor.constraint(greaterThanOrEqualTo: _window.leftAnchor, constant: 16),
            view.centerXAnchor.constraint(equalTo: _window.centerXAnchor)
        ])
        // Call layout to properly adjust view position and size.
        _window.layoutIfNeeded()
        
        let layoutGuide: UILayoutGuide
        if #available(iOS 11.0, *) {
            layoutGuide = _window.safeAreaLayoutGuide
        } else {
            layoutGuide = _window.layoutMarginsGuide
        }
        finalConstraint = view.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: Bauly.topMargin)
        finalConstraint.priority = .defaultHigh
        
        // Configure dismiss animator
        let dismissAnimator = self.dismissAnimator { [weak self, weak view, weak snapshot] in
            snapshot?.completionHandler?()
            guard let view = view else { return }
            self?.clean(after: view)
        }
        
        // Configure present animator
        let presentAnimator = UIViewPropertyAnimator(duration: snapshot.duration, dampingRatio: 0.66) {
            //self.initialConstraint.isActive = false
            self.finalConstraint.isActive = true
            _window.layoutIfNeeded()
        }
        // Assign work item so it can be canceled later in case
        dismissAction = {
            self.runningAnimator = dismissAnimator
            dismissAnimator.startAnimation()
        }
        presentAnimator.addCompletion { [weak self, weak snapshot, weak view] _ in
            guard let delay = snapshot?.delay, delay > 0 else { return }
            self?.dismissTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true) { [weak self] timer in
                guard view == self?.currentBanner,
                   view?.isTrackingTouch == false else {
                    return
                }
                timer.invalidate()
                self?.dismissAction?()
            }
        }
        currentBanner = view
        runningAnimator = presentAnimator
        
        presentAction = nil
        presentAction = {
            presentAnimator.startAnimation()
            if let style = snapshot.feedbackStyle {
                self.generate(feedback: style)
            }
        }
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        // Fire first animator
        presentAction?()
    }
    
    /**
     Method returning newly created `UIViewAnimateProperty` used for dismissal animation.
     - Parameters:
        - duration: Duration of the dismissal animation, in seconds.
        - window: `UIWindow` object of the banner.
        - completionHandler: Action called after banner slides out of the screen.
     */
    private func dismissAnimator(completionHandler: (() -> Void)?) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: 0.24, curve: .easeIn) {
            self.finalConstraint.isActive = false
            //self.initialConstraint.isActive = true
            self.currentBanner?.window?.layoutIfNeeded()
        }
        animator.addCompletion { _ in
            completionHandler?()
            guard let next = self.queue.first() else {
                return
            }
            self.present(snapshot: next)
        }
        return animator
    }
    
    /**
     Performs necessary cleanup after displayed banner.
     - Parameters:
        - view: Already displayed banner.
     */
    private func clean(after view: BaulyView) {
        if view == currentBanner {
            currentBanner = nil
        }
        if view.identifier == queue.first()?.identifier {
            queue.removeFirst()
        }
        runningAnimator = nil
    }
    
    /**
    Generates haptic feedback
    - Parameters:
        - style: Style of the haptic feedback.
    */
    private func generate(feedback style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func handleAppWillEnterBackgroundNotification(_ sender: Notification) {
        guard let action = presentAction, currentBanner != nil else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: action)
    }
}

internal extension Bauly {
    /// Helper container class to keep configuration of the banner.
    class Snapshot {
        let identifier: String
        let configurationHandler: ((BaulyView) -> Void)?
        let duration: TimeInterval
        let delay: TimeInterval
        let window: UIWindow?
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?
        let pressHandler: (() -> Void)?
        let completionHandler: (() -> Void)?
        
        init(configurationHandler: ((BaulyView) -> Void)?, duration: TimeInterval, dismissAfter delay: TimeInterval, in window: UIWindow?, feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?, pressHandler: (() -> Void)?, completionHandler: (() -> Void)?) {
            identifier = UUID().uuidString
            
            self.configurationHandler = configurationHandler
            self.duration = duration
            self.delay = delay
            self.window = window
            self.feedbackStyle = feedbackStyle
            self.pressHandler = pressHandler
            self.completionHandler = completionHandler
        }
    }
}
