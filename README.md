# Bauly

![Bauly Demo](https://i.imgur.com/Gpc7Tol.gif)

**Bauly** is a neat little library used to display compact message banners in your app. The design is inspired by stock banners visible in iOS 13 and newer. 

- Written in Swift 5
- iOS 10+ support
- Rotation, Dynamic Type, and Dark Mode support
- Haptic feedback
- Available via Swift Package Manager

##### Installation
Bauly can be installed via Swift Package Manager. To use it in your project, open Xcode, go to menu *File -> Swift Packages -> Add Package Dependency*, and paste this repo's URL:
```
https://github.com/wiencheck/Bauly.git
```

### Usage
**Bauly** is managed via a `shared` singleton instance.
It internally manages a queue of pending banners. Only one banner can be displayed at a time. Remember to call these methods **only from the main thread**.

##### Displaying banner
To display a banner, simply use the `present` method and provide title and other information for the banner:
```swift
public func present(title: String, 
                subtitle: String?, 
                icon: UIImage?, 
                duration: TimeInterval, 
                dismissAfter delay: TimeInterval, 
                in window: UIWindow?, 
                feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?, pressHandler: (() -> Void)?, 
                completionHandler: (() -> Void)?)
```

##### Customizing banner
In addition to the method described above, banners can be presented using a `present(configurationHandler:...)` method which provides the ability for directly customization of the banner:

```swift
func present(configurationHandler: ((BaulyView) -> Void)?, 
            duration: TimeInterval, 
            dismissAfter delay: TimeInterval, 
            in window: UIWindow?, 
            feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?, 
            pressHandler: (() -> Void)?, 
            completionHandler: (() -> Void)?)
```

By calling this method, you can customize the appearance of the banner and its other properties directly, for example:

```swift
Bauly.shared.present(configurationHandler: { bauly in
    // Tint is applied to the icon and title of the banner
    bauly.tintColor = .systemPurple
    bauly.visualEffect = .extraLight
    bauly.title = "This is Bauly!"
    bauly.subtitle = """
    Press me to have a little fun with colors.
    Btw, I support mutli-lined text and emojis easily
    😏
    """
    }...)
```

##### Displaying banner immediately
Both methods used for presenting a banner have a *sibling* method which forces the banner to be displayed immediately. It takes the same arguments as *normal* methods.

```swift
func forcePresent(...)
```

##### Dismissing banner

To manually dismiss the banner, use the ```dismiss``` method

```swift
func dismiss(completionHandler: (() -> Void)?)
```

**Note** If you want to use the `completionHandler` of this method, you should always check if any banner is currently visible before calling this method, by reading the `currentBanner` property, for example:

```swift
...
if Bauly.shared.currentBanner == nil {
    return
}
Bauly.shared.dismiss {
    print("Old banner dismissed!")
}
...
```

It's important as the `completionHandler` of this method doesn't get called if no banner has actually been dismissed.

### Todos

 - Write Tests
 - Support dismissal by dragging the banner out of the screen

License
----

MIT

[Check out my apps in App Store!](https://apps.apple.com/us/developer/adam-wienconek/id1331897870), downloading and buying in-app purchases greatly helps me in developing more stuff!
