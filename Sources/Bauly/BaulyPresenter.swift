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
    
    private var recentFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?
    private var cachedFeedbackGenerator: UIImpactFeedbackGenerator?
    
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
                 completion: (@MainActor (Bauly.PresentationState) -> Void)? = nil,
                 onTap: (@MainActor (BaulyView) -> Void)? = nil) {
        let lastIndex = queue.map(\.index).max() ?? -1
        let snapshot = Snapshot(index: lastIndex + 1,
                                viewConfiguration: configuration,
                                presentationOptions: presentationOptions,
                                completion: completion,
                                onTap: onTap)
        
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
    
    func dismiss(in windowScene: UIWindowScene? = nil,
                 completion: (@MainActor () -> Void)? = nil) {
        guard let scene = windowScene ?? applicationWindowScene(),
              let banner = currentBanner(in: scene) else {
            return
        }
        dismiss(banner: banner, completion: completion)
    }
    
    func cancelPendingBanners() {
        queue.removeAll()
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
        let index: Int
        var viewConfiguration: BaulyView.Configuration
        var presentationOptions: Bauly.PresentationOptions
        var completion: (@MainActor (Bauly.PresentationState) -> Void)?
        var onTap: (@MainActor (BaulyView) -> Void)?
    }
    
    func presentNextBanner() {
        guard let snapshot = queue.first else {
            return
        }
        present(withSnapshot: snapshot)
    }
    
    func present(withSnapshot snapshot: Snapshot) {
        /*
         This method is definitely too long and
         should be split in parts
         but I don't care.
         */
        let presentationOptions = snapshot.presentationOptions
        
        let banner = BaulyView()
        banner.index = snapshot.index
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
                .constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leftAnchor,
                            constant: 16),
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
        let finalConstraint = banner.topAnchor
            .constraint(equalTo: layoutGuide.topAnchor,
                        constant: presentationOptions.topPadding)
            .withPriority(.required)
        
        banner.presentAnimator = {
            let animator = UIViewPropertyAnimator(duration: presentationOptions.animationDuration,
                                                  dampingRatio: 0.66) {
                finalConstraint.isActive = true
                window.layoutIfNeeded()
            }
            animator.addCompletion { [weak self] in
                guard $0 == .end else { return }
                banner.wasPresented = true
                snapshot.completion?(.presented)
                
                guard presentationOptions.dismissAfter > 0 else {
                    return
                }
                self?.scheduleBannerDismissal(banner: banner,
                                              delay: presentationOptions.dismissAfter)
            }
            
            return animator
        }()
        
        banner.dismissAnimator = {
            let animator = UIViewPropertyAnimator(duration: presentationOptions.animationDuration,
                                                  dampingRatio: 0.66) {
                finalConstraint.isActive = false
                window.layoutIfNeeded()
            }
            animator.addCompletion { [weak self] in
                guard $0 == .end else { return }
                self?.clean(after: banner)
                snapshot.completion?(.dismissed)
                self?.presentNextBanner()
            }
            
            return animator
        }()
        banner.isDragGestureEnabled = presentationOptions.supportsDragging
        
        banner.trackedTouchSubject
            .sink { [weak self] isTracking, isWithinBounds, offset in
                guard !isTracking else {
                    banner.dismissTask = nil
                    return
                }
                if isWithinBounds {
                    snapshot.onTap?(banner)
                    if presentationOptions.isDismissedByTap {
                        self?.dismiss(banner: banner)
                    }
                }
                else {
                    if banner.transform.isIdentity {
                        self?.scheduleBannerDismissal(banner: banner)
                    }
                    else if offset < -BaulyView.dragLimitToAllowTouch {
                        self?.dismiss()
                    }
                    else {
                        UIView.animate(withDuration: 0.36,
                                       delay: 0,
                                       usingSpringWithDamping: 0.8,
                                       initialSpringVelocity: 1, animations: {
                            banner.transform = .identity
                        }, completion: {
                            guard $0 else { return }
                            self?.scheduleBannerDismissal(banner: banner)
                        })
                    }
                }
            }
            .store(in: &banner.cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak banner] _ in
                guard let banner else { return }
                NSLayoutConstraint.activate(initialConstraints)
                finalConstraint.isActive = banner.wasPresented
                window.layoutIfNeeded()
            }
            .store(in: &banner.cancellables)
        
        applicationStateObserver.applicationStatePublisher
            .debounce(for: .seconds(presentationOptions.animationDelay), scheduler: DispatchQueue.main)
            .filter { $0 && !banner.wasPresented }
            .sink { [weak self] _ in
                snapshot.completion?(.willPresent(banner))
                if let feedbackStyle = presentationOptions.feedbackStyle {
                    self?.generateHapticFeedback(withStyle: feedbackStyle)
                }
                banner.presentAnimator.startAnimation()
            }
            .store(in: &banner.cancellables)
    }
    
    func dismiss(banner: BaulyView,
                 completion: (@MainActor () -> Void)? = nil) {
        banner.dismissTask = nil
        
        banner.presentAnimator = nil
        banner.dismissAnimator.addCompletion {
            guard $0 == .end else { return }
            completion?()
        }
        banner.dismissAnimator.startAnimation()
    }
    
    func clean(after view: BaulyView) {
        view.cancellables.removeAll()
        view.removeFromSuperview()
        queue.removeAll { $0.index == view.index }
    }
    
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
    
    func scheduleBannerDismissal(banner: BaulyView, delay: TimeInterval = 1.5) {
        banner.dismissTask = Task { [weak self, weak banner] in
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard let banner else {
                    return
                }
                self?.dismiss(banner: banner)
            } catch {}
        }
    }
    
}
