//
//  BaulyPresenter.swift
//
//  Copyright (c) 2022 Adam Wienconek (https://github.com/wiencheck)
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
import Combine

fileprivate let bannerViewTag = 9_143_625

@MainActor
final class BaulyPresenter {
    
    /// MARK: Public properties
    
    // MARK: Private properties
    
    /// Constraint keeping banner in its initial position (outside of the screen)
    private var initialConstraint: NSLayoutConstraint!
    
    /// Constraint keeping banner in its final position (below top edge of the screen)
    private var finalConstraint: NSLayoutConstraint!
    
    private var dismissTask: Task<Void, Never>? {
        willSet { dismissTask?.cancel() }
    }
    private var presentAnimator: UIViewPropertyAnimator?
    private var dismissAnimator: UIViewPropertyAnimator?
    
    private var recentFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?
    private var cachedFeedbackGenerator: UIImpactFeedbackGenerator?
    
    private var applicationStateCancellable: AnyCancellable?
    private lazy var applicationStateObserver = ApplicationStateObserver()
    
    /// Queue of upcoming banners.
    private var queue: [Snapshot] = []
        
    func currentBanner(in windowScene: UIWindowScene) -> BaulyView? {
        let window: UIWindow?
        if #available(iOS 15.0, *) {
            window = windowScene.keyWindow
        }
        else {
            window = windowScene.windows.first(where: \.isKeyWindow)
        }
        
        return window?.viewWithTag(bannerViewTag) as? BaulyView
    }
    
    func present(withConfiguration configuration: BaulyView.Configuration,
                 presentationOptions: Bauly.PresentationOptions = .init(),
                 completion: (@MainActor (Bauly.PresentationState) -> Void)? = nil) {
        let snapshot = Snapshot(viewConfiguration: configuration,
                                presentationOptions: presentationOptions,
                                completionHandler: completion)
        if queue.isEmpty {
            queue.append(snapshot)
            presentNextBanner()
        }
        else if presentationOptions.presentImmediately {
            queue.insert(snapshot, at: 1)
            dismiss()
        }
        else {
            queue.append(snapshot)
        }
    }
    
    func dismiss(completionHandler: (@MainActor () -> Void)? = nil) {
        dismissTask = nil
        presentAnimator?.stopAnimation(true)
        
        dismissAnimator?.addCompletion {
            assert(
                $0 == .end, "Animator finished in incorrect state!"
            )
            completionHandler?()
        }
        dismissAnimator?.startAnimation()
    }
    
}

// MARK: Private
private extension BaulyPresenter {
    
    struct Snapshot {
        var viewConfiguration: BaulyView.Configuration
        var presentationOptions: Bauly.PresentationOptions
        var completionHandler: (@MainActor (Bauly.PresentationState) -> Void)?
    }
    
    func presentNextBanner() {
        guard let snapshot = queue.first else {
            return
        }
        if let windowScene = snapshot.presentationOptions.windowScene ?? .focused {
            assert(
                currentBanner(in: windowScene) == nil,
                "Previous banner was not dismissed!"
            )
        }
        present(withSnapshot: snapshot)
    }
    
    func present(withSnapshot snapshot: Snapshot) {
        let presentationOptions = snapshot.presentationOptions
        
        let banner = BaulyView()
        banner.contentConfiguration = snapshot.viewConfiguration
        banner.tag = bannerViewTag
        banner.addTarget(self,
                         action: #selector(handleBannerTouched),
                         for: .touchDown)
        banner.addTarget(self,
                         action: #selector(handleBannerTouchCancelled),
                         for: [.touchUpOutside, .touchCancel])
        if presentationOptions.isDismissedByTap {
            banner.addTarget(self,
                             action: #selector(handleBannerTapped),
                             for: .primaryActionTriggered)
        }
        
        
        var window: UIWindow!
        if #available(iOS 13.0, *) {
            window = (snapshot.presentationOptions.windowScene ?? .focused)?.keyWindow
        }
        else {
            window = UIApplication.shared.keyWindow
        }
        assert(
            window != nil,
            "Could not obtain window to display banner"
        )
        
        window.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        initialConstraint = banner.bottomAnchor
            .constraint(equalTo: window.topAnchor)
            .withPriority(.defaultLow)
        NSLayoutConstraint.activate([
            initialConstraint,
            banner.leftAnchor
                .constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leftAnchor, constant: 16),
            banner.centerXAnchor
                .constraint(equalTo: window.centerXAnchor)
        ])
        
        // Call layout to properly adjust view position and size.
        window.layoutIfNeeded()
        
        let layoutGuide: UILayoutGuide
        if #available(iOS 11.0, *) {
            layoutGuide = window.safeAreaLayoutGuide
        } else {
            layoutGuide = window.layoutMarginsGuide
        }
        finalConstraint = banner.topAnchor
            .constraint(equalTo: layoutGuide.topAnchor, constant: presentationOptions.topPadding)
            .withPriority(.required)
        
        presentAnimator = UIViewPropertyAnimator(duration: presentationOptions.animationDuration, dampingRatio: 0.66) {
            self.finalConstraint.isActive = true
            window.layoutIfNeeded()
        }
        presentAnimator!.addCompletion { [weak self] in
            assert(
                $0 == .end, "Animator finished in incorrect state!"
            )
            snapshot.completionHandler?(.presented)
            
            guard presentationOptions.dismissAfter > 0 else {
                return
            }
            self?.scheduleBannerDismissal(after: presentationOptions.dismissAfter)
        }
        
        dismissAnimator = UIViewPropertyAnimator(duration: presentationOptions.animationDuration, dampingRatio: 0.66) {
            self.finalConstraint.isActive = false
            window.layoutIfNeeded()
        }
        dismissAnimator!.addCompletion { [weak self] in
            assert(
                $0 == .end, "Animator finished in incorrect state!"
            )
            snapshot.completionHandler?(.dismissed)
            self?.clean(after: banner)
            self?.presentNextBanner()
        }
        
        applicationStateCancellable = applicationStateObserver.applicationStatePublisher
            .debounce(for: .seconds(presentationOptions.animationDelay), scheduler: DispatchQueue.main)
            .sink { [weak self] isActive in
                guard isActive else { return }
                
                snapshot.completionHandler?(.willPresent(banner))
                if let feedbackStyle = presentationOptions.feedbackStyle {
                    self?.generateHapticFeedback(withStyle: feedbackStyle)
                }
                self?.presentAnimator?.startAnimation()
            }
    }
    
    func clean(after view: BaulyView) {
        view.removeFromSuperview()
        queue.removeFirst()
    }
    
    /**
     Generates haptic feedback
     - Parameters:
     - style: Style of the haptic feedback.
     */
    func generateHapticFeedback(withStyle feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator: UIImpactFeedbackGenerator
        if feedbackStyle == recentFeedbackStyle, let cachedFeedbackGenerator {
            generator = cachedFeedbackGenerator
        }
        else {
            generator = UIImpactFeedbackGenerator(style: feedbackStyle)
        }
        
        generator.impactOccurred()
        recentFeedbackStyle = feedbackStyle
    }
    
    func scheduleBannerDismissal(after delay: TimeInterval) {
        dismissTask = Task { [weak dismissAnimator] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else {
                return
            }
            guard let animator = dismissAnimator else {
                assertionFailure("dismissAnimator was nil but dismiss work item has not been canceled!")
                return
            }
            animator.startAnimation()
        }
    }
    
    @objc func handleBannerTouched(_ sender: BaulyView) {
        dismissTask = nil
    }
    
    @objc func handleBannerTouchCancelled(_ sender: BaulyView) {
        scheduleBannerDismissal(after: 1.5)
    }
    
    @objc func handleBannerTapped(_ sender: BaulyView) {
        dismiss()
    }
    
}
