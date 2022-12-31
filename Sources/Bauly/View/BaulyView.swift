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
final public class BaulyView: UIView {
            
    // MARK: Public properties
    
    /// Current configuration of banner's content.
    public var contentConfiguration: Configuration = .init() {
        didSet {
            applyConfiguration()
            superview?.layoutIfNeeded()
        }
    }
    
    // MARK: Internal properties
    var index = 0
    var presentAnimator: UIViewPropertyAnimator! {
        willSet { presentAnimator?.stopAnimation(true) }
    }
    var dismissAnimator: UIViewPropertyAnimator! {
        willSet { dismissAnimator?.stopAnimation(true) }
    }
    var dismissTask: Task<Void, Never>? {
        willSet { dismissTask?.cancel() }
    }
    let trackedTouchSubject: PassthroughSubject<(isTracking: Bool, withinBounds: Bool, offset: CGFloat), Never> = .init()
    var wasPresented = false
    var cancellables: Set<AnyCancellable> = []
        
    // MARK: Appearance
    
    /// Blur effect style used for banner's background.
    public var backgroundBlurEffectStyle: UIBlurEffect.Style = .prominent {
        didSet {
            visualEffectView.effect = UIBlurEffect(style: backgroundBlurEffectStyle)
        }
    }
    
    // MARK: Layout elements
        
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
    
    private lazy var tapGesture: UIGestureRecognizer = {
        let tap = UILongPressGestureRecognizer(target: self,
                                               action: #selector(handleLongPress))
        tap.delegate = self
        tap.minimumPressDuration = 0
        
        return tap
    }()
    
    private lazy var dragGesture: UIGestureRecognizer = {
        let drag = UIPanGestureRecognizer(target: self,
                                          action: #selector(handleDrag))
        drag.delegate = self
        
        return drag
    }()
    
    /// View used for displaying blur effect.
    private lazy var visualEffectView = UIVisualEffectView(effect:
                                                                    UIBlurEffect(style: backgroundBlurEffectStyle)
    )
    
    private var highlightedAnimator: UIViewPropertyAnimator! {
        willSet { highlightedAnimator?.stopAnimation(true) }
    }
    
    /// Special layer used for creating rounded shadow.
    private var shadowLayer: CAShapeLayer!
    private var dragStartingLocation: CGPoint!
    private var dragOffset: CGFloat = 0
    
    public var isHighlighted: Bool = false {
        didSet {
            guard isHighlighted != oldValue else {
                return
            }
            setHighlighted(isHighlighted)
        }
    }
    
    class var dragLimitToAllowTouch: CGFloat { 12 }
        
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Na-uh")
    }
        
    var isDragGestureEnabled: Bool {
        get { dragGesture.isEnabled }
        set { dragGesture.isEnabled = newValue }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height / 2
        visualEffectView.layer.cornerRadius = layer.cornerRadius
        
        // Set shadow
        if shadowLayer == nil {
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
        titleLabel.textColor = tintColor
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(dragGesture)
        
        subviews.forEach { $0.isUserInteractionEnabled = false }
    }
    
    func setHighlighted(_ highlighted: Bool) {
        let alpha: CGFloat = highlighted ? 0.6 : 1
        
        highlightedAnimator = .init(duration: 0.16, curve: .linear) {
            self.titleLabel.alpha = alpha
            self.subtitleLabel.alpha = alpha
            self.iconView.alpha = alpha
        }
        highlightedAnimator.startAnimation()
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
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)
        
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
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leftAnchor.constraint(equalTo: leftAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualEffectView.rightAnchor.constraint(equalTo: rightAnchor),
            
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            contentStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
        ])
    }
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self)
        let isWithinBounds = self.bounds
            .insetBy(dx: -Self.dragLimitToAllowTouch, dy: -Self.dragLimitToAllowTouch)
            .contains(location)
        && (abs(dragOffset) < Self.dragLimitToAllowTouch)
        
        switch sender.state {
        case .began, .changed:
            isHighlighted = isWithinBounds
            trackedTouchSubject.send((true, isWithinBounds, dragOffset))
                                
        case .ended:
            isHighlighted = false
            trackedTouchSubject.send((false, isWithinBounds, dragOffset))

        case .cancelled:
            isHighlighted = false
            trackedTouchSubject.send((false, false, 0))

        default:
            break
        }
    }
    
    @objc func handleDrag(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: superview)
        let dragLimit: CGFloat = Self.dragLimitToAllowTouch * 0.8
        
        switch sender.state {
        case .began:
            dragStartingLocation = location
            
        case .changed:
            var offset = location.y - dragStartingLocation.y
            
            if offset > dragLimit {
                offset = dragLimit * (1 + log10(offset / dragLimit))
            }
            dragOffset = offset
            transform = CGAffineTransform(translationX: 0,
                                          y: offset)
            
        case .ended, .cancelled:
            dragOffset = 0
            
        default:
            break
        }
    }
    
}

extension BaulyView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
