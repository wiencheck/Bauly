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

@MainActor
final class BaulyPresenter {
        
    // MARK: Private properties
    
    /// Constraint keeping banner in its initial position (outside of the screen)
    private var initialConstraint: NSLayoutConstraint!
    
    /// Constraint keeping banner in its final position (below top edge of the screen)
    private var finalConstraint: NSLayoutConstraint!
    
    private var dismissTask: Task<Void, Never>? {
        willSet { dismissTask?.cancel() }
    }
    private var presentAnimator: UIViewPropertyAnimator? {
        willSet { presentAnimator?.stopAnimation(true) }
    }
    private var dismissAnimator: UIViewPropertyAnimator? {
        willSet { dismissAnimator?.stopAnimation(true) }
    }
    
    private var recentFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?
    private var cachedFeedbackGenerator: UIImpactFeedbackGenerator?
    
    private var cancellables: Set<AnyCancellable> = []
    private lazy var applicationStateObserver = ApplicationStateObserver()
    
    /// Queue of upcoming banners.
    private var queue: [Snapshot] = []
        
    func currentBanner(in windowScene: UIWindowScene) -> BaulyView? {
        let window = windowScene.keyWindow
        return window?.subviews.first(where: {
            $0 is BaulyView
        }) as? BaulyView
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
        presentAnimator = nil
        
        dismissAnimator?.addCompletion {
            guard $0 == .end else { return }
            completionHandler?()
        }
        dismissAnimator?.startAnimation()
    }
    
    func applicationWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        
        return scenes.first(where: {
            $0.activationState == .foregroundActive
        }) ?? scenes.first
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
        present(withSnapshot: snapshot)
    }
    
    func present(withSnapshot snapshot: Snapshot) {
        let presentationOptions = snapshot.presentationOptions
        
        let banner = BaulyView()
        banner.contentConfiguration = snapshot.viewConfiguration
        
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            let windowScene = snapshot.presentationOptions.windowScene ?? applicationWindowScene()
            window = windowScene?.keyWindow
        }
        else {
            window = UIApplication.shared.keyWindow
        }
        guard let window else {
            print("Could not obtain window to display banner")
            return
        }
        
        window.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        let initialConstraints: [NSLayoutConstraint] = [
            banner.bottomAnchor
                .constraint(equalTo: window.topAnchor)
                .withPriority(.defaultLow),
            banner.leftAnchor
                .constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leftAnchor, constant: 16),
            banner.centerXAnchor
                .constraint(equalTo: window.centerXAnchor)
        ]
        NSLayoutConstraint.activate(initialConstraints)
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
            guard $0 == .end else { return }
            banner.wasPresented = true
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
            guard $0 == .end else { return }
            snapshot.completionHandler?(.dismissed)
            self?.clean(after: banner)
            self?.presentNextBanner()
        }
        
        assert(
            cancellables.isEmpty,
            "Observers for previous banner were not removed"
        )
        
        banner.tapGesturePublisher
            .sink { [weak self] gesture in
                let location = gesture.location(in: banner)
                let isTouched = banner.bounds
                    .insetBy(dx: -25, dy: -25)
                    .contains(location)
                
                switch gesture.state {
                case .began, .changed:
                    self?.dismissTask = nil
                    banner.isHighlighted = isTouched
                                        
                case .ended:
                    if isTouched {
                        self?.scheduleBannerDismissal()
                    }
                    else {
                        self?.dismiss()
                    }
                    
                case .cancelled:
                    self?.scheduleBannerDismissal()
                    
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self, weak banner] _ in
                guard let banner else { return }
                NSLayoutConstraint.activate(initialConstraints)
                self?.finalConstraint.isActive = banner.wasPresented
                window.layoutIfNeeded()
            }
            .store(in: &cancellables)
        
        applicationStateObserver.applicationStatePublisher
            .debounce(for: .seconds(presentationOptions.animationDelay), scheduler: DispatchQueue.main)
            .filter { $0 && !banner.wasPresented }
            .sink { [weak self] _ in
                snapshot.completionHandler?(.willPresent(banner))
                if let feedbackStyle = presentationOptions.feedbackStyle {
                    self?.generateHapticFeedback(withStyle: feedbackStyle)
                }
                self?.presentAnimator?.startAnimation()
            }
            .store(in: &cancellables)
    }
    
    func clean(after view: BaulyView) {
        view.removeFromSuperview()
        queue.removeFirst()
        cancellables.removeAll()
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
    
    func scheduleBannerDismissal(after delay: TimeInterval = 1.5) {
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
    
    func updateConstraints() {
        
    }
    
}
