//
//  BaulyView.swift
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

/**
Class representing a banner view. It exposes some properties for modyfing the appearance and content.
*/
final public class BaulyView: UIControl {
    
    // MARK: Public properties
    
    /// Current configuration of banner's content.
    public var contentConfiguration: Configuration = .init() {
        didSet {
            applyConfiguration()
            superview?.layoutIfNeeded()
        }
    }
    
    /// Text diplayed in the main label of the banner.
    @available(*, deprecated, message: "Use contentConfiguration property to set this value.")
    public var title: String {
        get { contentConfiguration.title ?? "" }
        set { contentConfiguration.subtitle = newValue }
    }
    
    /// Text displayed in the detail label of the banner.
    @available(*, deprecated, message: "Use contentConfiguration property to set this value.")
    public var subtitle: String? {
        get { contentConfiguration.subtitle }
        set { contentConfiguration.subtitle = newValue }
    }
    
    /// Image displayed in the banner. Should have equal width and height.
    @available(*, deprecated, message: "Use contentConfiguration property to set this value.")
    public var icon: UIImage? {
        get { contentConfiguration.image }
        set { contentConfiguration.image = newValue }
    }
        
    // MARK: Appearance
    
    /// Blur effect style used for banner's background.
    public var backgroundBlurEffectStyle: UIBlurEffect.Style = .prominent {
        didSet {
            visualEffectView.effect = UIBlurEffect(style: backgroundBlurEffectStyle)
        }
    }
    
    // MARK: Layout elements
    
    /* We hide elements initially so the stack is correctly sized depending on content. */
    
    /// Image view used for displaying icon.
    public private(set) lazy var iconView: UIImageView = {
        let im = UIImageView()
        im.contentMode = .scaleAspectFit
        im.preferredSymbolConfiguration = .init(pointSize: 20)
        
        return im
    }()
    
    /// Main label of the banner.
    public private(set) lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = .preferredFont(forTextStyle: .subheadline, weight: .semibold)
        
        return l
    }()
    
    /// Secondary label of the banner.
    public private(set) lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = .preferredFont(forTextStyle: .footnote, weight: .medium)
        l.textColor = .secondaryLabel
        
        return l
    }()
    
    /// View used for displaying blur effect.
    private lazy var visualEffectView = UIVisualEffectView(effect:
                                                                    UIBlurEffect(style: backgroundBlurEffectStyle)
    )
    
    private var highlightedAnimator: UIViewPropertyAnimator? {
        willSet { highlightedAnimator?.stopAnimation(true) }
        didSet { highlightedAnimator?.startAnimation() }
    }
    
    /// Special layer used for creating rounded shadow.
    private var shadowLayer: CAShapeLayer!
    
    public override var isHighlighted: Bool {
        didSet { setHighlighted(isHighlighted) }
    }
        
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Na-uh")
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
    
    public override var tintColor: UIColor! {
        didSet {
            titleLabel.textColor = tintColor
        }
    }
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        titleLabel.textColor = tintColor
    }
    
}

// MARK: Private
private extension BaulyView {
    
    func commonInit() {
        visualEffectView.layer.masksToBounds = true
        setupView()
        subviews.forEach { $0.isUserInteractionEnabled = false }
        addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
    }
    
    func setHighlighted(_ highlighted: Bool) {
        let alpha: CGFloat = highlighted ? 0.6 : 1
        
        highlightedAnimator = .init(duration: 0.16, curve: .linear) {
            self.titleLabel.alpha = alpha
            self.subtitleLabel.alpha = alpha
            self.iconView.alpha = alpha
        }
    }
    
    func applyConfiguration() {
        titleLabel.text = contentConfiguration.title
        titleLabel.isHidden = (contentConfiguration.title == nil)
        
        subtitleLabel.text = contentConfiguration.subtitle
        subtitleLabel.isHidden = (contentConfiguration.subtitle == nil)
        
        iconView.image = contentConfiguration.image
        iconView.isHidden = (contentConfiguration.image == nil)
    }
    
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
            s.spacing = 12
            return s
        }()

        addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            contentStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 96)
        ])
    }
    
    @objc func handleTouchUpInside(_ sender: BaulyView) {
        sendActions(for: .primaryActionTriggered)
    }
    
}

@available(iOS 14.0, *)
extension BaulyView: UIContentView {
    
    @available(iOS, deprecated, message: "Prefer using the `contentConfiguration` property directly")
    public var configuration: UIContentConfiguration {
        get { contentConfiguration }
        set { contentConfiguration = newValue as! Configuration }
    }
    
}
