//
//  BaulyView.swift
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
Class representing a banner view. It exposes some properties for modyfing the appearance and content.
*/
final public class BaulyView: UIView {
    
    // MARK: Public properties
    
    /// Text diplayed in the main label of the banner.
    public var title: String {
        get {
            return titleLabel.text ?? ""
        } set {
            titleLabel.text = newValue
            titleLabel.isHidden = newValue.isEmpty
        }
    }
    
    /// Text displayed in the detail label of the banner.
    public var subtitle: String? {
        get {
            return subtitleLabel.text
        } set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = newValue == nil
        }
    }
    
    /// Image displayed in the banner. Should have equal width and height.
    public var icon: UIImage? {
        get {
            return iconView.image
        } set {
            iconView.image = newValue
            iconView.isHidden = newValue == nil
        }
    }
        
    // MARK: Appearance
    
    /// Blur effect style used for banner's background.
    public var visualEffect: UIBlurEffect.Style = .prominent {
        didSet {
            visualEffectView.effect = UIBlurEffect(style: visualEffect)
        }
    }
    
    // MARK: Private properties
    
    /// Unique identifier of the banner.
    internal var identifier: String?
    
    /// Action called after pressing the banner.
    internal var pressHandler: (() -> Void)?
    
    // MARK: Layout elements
    
    /* We hide elements initially so the stack is correctly sized depending on content. */
    
    /// Image view used for displaying icon.
    private lazy var iconView: UIImageView = {
        let im = UIImageView()
        im.contentMode = .scaleAspectFit
        im.isHidden = true
        return im
    }()
    
    /// Main label of the banner.
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.isHidden = true
        l.textAlignment = .center
        if #available(iOS 11.0, *) {
            l.font = .preferredFont(forTextStyle: .subheadline, weight: .semibold)
        } else {
            l.font = .preferredFont(forTextStyle: .subheadline)
        }
        return l
    }()
    
    /// Secondary label of the banner.
    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.isHidden = true
        l.textAlignment = .center
        if #available(iOS 11.0, *) {
            l.font = .preferredFont(forTextStyle: .footnote, weight: .medium)
        } else {
            l.font = .preferredFont(forTextStyle: .footnote)
        }
        if #available(iOS 13.0, *) {
            l.textColor = .secondaryLabel
        } else {
            l.textColor = .darkGray
        }
        return l
    }()
    
    /// View used for displaying blur effect.
    private dynamic lazy var visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: visualEffect))
    
    /// Special layer used for creating rounded shadow.
    private var shadowLayer: CAShapeLayer!
        
    // MARK: Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        visualEffectView.layer.cornerRadius = layer.cornerRadius
        // Set shadow
        guard shadowLayer == nil else {
            return
        }
        shadowLayer = CAShapeLayer()
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        shadowLayer.fillColor = UIColor.clear.cgColor

        shadowLayer.shadowColor = UIColor.darkGray.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = CGSize(width: 0, height: 2.0)
        shadowLayer.shadowOpacity = 0.2
        shadowLayer.shadowRadius = 16
        
        layer.insertSublayer(shadowLayer, at: 0)
    }
    
    // MARK: Private methods
    
    private func commonInit() {
        visualEffectView.layer.masksToBounds = true
        setupView()
        subviews.forEach {
            $0.isUserInteractionEnabled = false
        }
    }
}

// MARK: Handling Tint Color changes
public extension BaulyView {
    override var tintColor: UIColor! {
        didSet {
            titleLabel.textColor = tintColor
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        titleLabel.textColor = tintColor
    }
}

// MARK: Touch
public extension BaulyView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.16) {
            self.alpha = 0.6
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.16) {
            self.alpha = 1
        }
        pressHandler?()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        // Support dragging, maybe one day...
    }
}

private extension BaulyView {
    func setupView() {
        //Configure background
        backgroundColor = .clear
        addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leftAnchor.constraint(equalTo: leftAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualEffectView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        // Configure labels
        let labelStack: UIStackView = {
            let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            s.axis = .vertical
            s.spacing = 0
            return s
        }()
        
        let contentStack: UIStackView = {
            let s = UIStackView(arrangedSubviews: [iconView, labelStack])
            s.axis = .horizontal
            s.alignment = .center
            s.distribution = .fill
            s.spacing = 12
            return s
        }()
        addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Constraints for stack
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            contentStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
            // Constraints for subviews
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

fileprivate extension UIFont {
    @available (iOS 11.0, *)
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        return metrics.scaledFont(for: font)
    }
}
