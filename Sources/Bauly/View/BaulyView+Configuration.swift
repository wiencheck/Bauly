//
//  File.swift
//  
//
//  Created by Adam Wienconek on 29/11/2022.
//

import Foundation
import UIKit.UIImage

public extension BaulyView {
    
    struct Configuration: Sendable {
        public var title: String?
        public var subtitle: String?
        public var image: UIImage?
        
        public init(title: String? = nil,
                    subtitle: String? = nil,
                    image: UIImage? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.image = image
        }
    }
    
}

@available(iOS 14.0, *)
extension BaulyView.Configuration: UIContentConfiguration {
    
    public func makeContentView() -> UIView & UIContentView {
        let view = BaulyView(frame: .zero)
        view.contentConfiguration = self
        
        return view
    }
    
    public func updated(for state: UIConfigurationState) -> BaulyView.Configuration {
        return self
    }
    
}
