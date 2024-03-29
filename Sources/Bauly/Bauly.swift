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

import Foundation
import UIKit

/**
 Class used for displaying banners with similar look to the native compact banners seen in `iOS 13.0` and newer.
 */
@MainActor
public class Bauly {
    
    private static let presenter = BaulyPresenter()
    
    /**
     Returns currently displayed banner view in window scene.
     
     - Parameters:
        - windowScene: Window scene object in which banner was presented. If `nil` is passed a first active scene is used.
     */
    public class func currentBanner(in windowScene: UIWindowScene? = nil) -> BaulyView? {
        guard let scene = windowScene ?? presenter.applicationWindowScene() else {
            return nil
        }
        return presenter.currentBanner(in: scene)
    }
    
    /**
     Presents new banner banner.
     
     If there are any banners on the screen, or pending in the queue, the new banner will be displayed as last unless stated otherwise in `presentationOptions`.
     - Parameters:
        - configuration: Configuration values for banner.
        - presentationOptions: Options for configuring how banner's presentation occurs.
        - onTap: Closure called when user taps the presented banner.
        - completion: Closure called whenever banner status changes.
     */
    public class func present(withConfiguration configuration: BaulyView.Configuration,
                              presentationOptions: Bauly.PresentationOptions = .init(),
                              onTap: (@MainActor (BaulyView) -> Void)? = nil,
                              completion: (@MainActor (Bauly.PresentationState) -> Void)? = nil) {
        presenter.present(withConfiguration: configuration,
                          presentationOptions: presentationOptions,
                          completion: completion,
                          onTap: onTap)
    }
    
    /**
     Dismisses currenly displayed banner, if there is any.
     - Parameters:
        - completion: Handler called after banner slides out of the screen.
     
     If no banner is visible when calling this method, the `completion` will not be called.
     */
    public class func dismiss(completion: (@MainActor () -> Void)? = nil) {
        presenter.dismiss(completion: completion)
    }
    
    /**
     Removes pending banners from the queue.
     */
    public class func cancelPendingBanners() {
        presenter.cancelPendingBanners()
    }
    
    @available(*, unavailable)
    init() {}
    
}
