# Bauly

![Bauly Demo](https://i.imgur.com/qcalhgg.gif)

**Bauly** is a neat little library used to display compact message banners in your app. The design is inspired by stock banners visible in iOS 13 and newer. 

- Highly customizable ✅
- Written using UIKit ✅
- iOS 13+ support ✅
- Rotation, Dynamic Type, Concurrency, and Dark Mode support ✅
- Haptic feedback ✅
- Available via Swift Package Manager ✅

##### Installation
Bauly can be installed via Swift Package Manager. To use it in your project, open Xcode, go to menu *File -> Swift Packages -> Add Package Dependency*, and paste this repo's URL:
```
https://github.com/wiencheck/Bauly.git
```

### Usage
Using Bauly is fun and easy. All you need to do is provide values to be displayed and optionally adjust how the banner should be displayed.

##### Displaying banner
To display a banner use the `present` method:

```swift
public class func present(withConfiguration configuration: BaulyView.Configuration,
                          presentationOptions: Bauly.PresentationOptions = .init(),
                          completion: (@MainActor (Bauly.PresentationState) -> Void)? = nil)
```

##### Customizing banner
To set banner's contents you use BaulyView.Configuration struct:
```swift
public extension BaulyView {
    
    struct Configuration {
        public var title: String?
        public var subtitle: String?
        public var image: UIImage?
    }
    
}
```
Each property of configuration is optional. If no value is set the corresponding element will be hidden from the banner.

In addition to providing configuration values you can customize the banner view directly in `completion` block. 

The `PresentationState` enum contains case `.willPresent(BaulyView)` which you can use to obtain reference to the banner and customize it like with any other `UIView` (`BaulyView` is an `UIControl` subclass)

`BaulyView` exposes access to 3 main elements: 
- `titleLabel`: `UILabel` object displayed at the top
- `subtitleLabel`: `UILabel` object displayed under title label
- `iconView`: `UIImageView` displayed next to both labels

`UIBlurEffect` is used for the banner's background. Its style can be changed by setting `backgroundBlurEffectStyle` value and uses `.prominent` style by default.

```swift
    Bauly.present(withConfiguration: configuration,
                  completion: { state in
        switch state {
            case .willPresent(let banner):
                banner.overrideUserInterfaceStyle = .dark
                banner.tintColor = .purple
                banner.titleLabel.textColor = .yellow
                banner.iconView.preferredSymbolConfiguration = .init(pointSize: 26)
                
            default:
                break
            }
        })
```

##### Customizing banner's presentation
When calling `present` method you can provide your own options for presenting the banner. 

```swift
public extension Bauly {
    
    struct PresentationOptions {
        public var topPadding: CGFloat
        public var animationDuration: TimeInterval
        public var dismissAfter: TimeInterval
        public var animationDelay: TimeInterval
        public var presentImmediately: Bool
        public var windowScene: UIWindowScene?
        public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?
        public var isDismissedByTap: Bool
    }
    
}
```

All properties have default values so you can choose which one you'd like to modify.
- `topPadding`: Amount of space between banner and safe area top margin.
- `animationDuration`: Duration of the presentation / dismissal animation (in seconds).
- `dismissAfter`: Time after banner disappears from the screen (in seconds).
- `animationDelay`: Delay for the animation to start.
- `presentImmediately`: Controls whether banner will wait for its turn in the queue or will be displayed immediately.
- `windowScene`: Window scene used for displaying the banner.
- `feedbackStyle`: Style of haptic feedback which occurs when banner is presented.
- `isDismissedByTap`: Indicates whether tapping on the banner should dismiss it.

##### Displaying banner immediately
By default every time `present` is called a new banner is placed at the end of the queue and will be presented after all previous banners have been displayed. 

This behaviour can be changed so that new banner will be placed at next position in the queue and will be presented immediately causing any other banner on the screen to slide out of the screen early.
To do that set `presentImmediately` property to `true` on the `PresentationOptions` which you pass to the present method

```swift
    var options = Bauly.PresentationOptions()
    options.presentImmediately = true

    Bauly.present(withConfiguration: configuration,
                  presentationOptions: options,
                  completion: { state in
    ...
```

##### Dismissing banner
To manually dismiss the banner, use the `dismiss(completion:)` method.

It takes optional closure which gets called once current banner disappears from the screen. If no banner was displayed at the moment of calling this method the `completion` will not be called.

If you want to make sure that a banner was visible before calling this method you can use the `currentBanner(in windowScene:)` method and check its return value.

```swift
    guard Bauly.currentBanner() != nil else {
        return
    }
    Bauly.dismiss {
        // Continue after dismissing the banner
    }
```

##### Responding to touches
Method `present` accepts optional closure which gets called when user taps on the presented banner:

```swift
    Bauly.present(withConfiguration: configuration,
                  presentationOptions: options,
                  onTap: { banner in
            print("Banner was tapped!")
        },
        ...
```

### Todos
 - Write Tests
 - <s>Support dismissal by dragging the banner out of the screen</s> Done in 1.1.0

License
----

MIT

[Check out my apps in App Store!](https://apps.apple.com/us/developer/adam-wienconek/id1331897870), downloading and buying in-app purchases greatly helps me in developing more stuff!
