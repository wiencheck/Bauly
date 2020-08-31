# Bauly

![Bauly Demo](https://i.imgur.com/tAx7gJd.gif)

**Bauly** is a neat little library used to displaying compact message banners in your app. The design is inspired by stock banners visible in iOS 13 and newer. 

- Written in Swift 5
- iOS 10+ support
- Rotation, Dynamic Type and Dark Mode support
- Available via Swift Package Manager

##### Installation
Bauly can be installed via Swift Package Manager. To use it in your project, open Xcode and go to menu *File -> Swift Packages -> Add Package Dependency* and past this repo's address:
```
https://github.com/wiencheck/Bauly.git
```

### Usage
**Bauly** is managed via `shared` singleton instance.
It manages internally a queue of pending banners. Only one banner can be displayed at the time. Remember to call methods **only from main thread**.

##### Displaying banner
To display a banner use one of the following methods:
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
In addition to methods described above, banners can be presented using methods which provide an entry for directly customizing the banner.

```swift
func present(configurationHandler: ((BaulyView) -> Void)?, 
            duration: TimeInterval, 
            dismissAfter delay: TimeInterval, 
            in window: UIWindow?, 
            feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?, 
            pressHandler: (() -> Void)?, 
            completionHandler: (() -> Void)?)
```

By calling this method you can customize appearance of the banner and its other properties directly, for example:

```swift
Bauly.shared.present(configurationHandler: { bauly in
    // Tint is applied to the icon and title of the banner
    bauly.tintColor = .systemPurple
    bauly.visualEffect = .extraLight
    bauly.title = "This is Bauly!"
    bauly.subtitle = """
    Press me to have a little fun with colors.
    Btw, I support mutli-line text and emojis easily
    😏
    """
    }...)
```

##### Displaying banner immediately
Both methods used for presenting a banner have a *sister* method which forces the banner to be displayed immediately. It has the same arguments as *normal* methods.

```swift
func forcePresent(...)
```

##### Dismissing banner

To manually dismiss the banner use the ```dismiss``` method
```swift
func dismiss(completionHandler: (() -> Void)?)
```

### Todos

 - Write Tests
 - Add Night Mode

License
----

MIT

[Check out my apps in App Store!](https://apps.apple.com/us/developer/adam-wienconek/id1331897870), downloading and buying in-app purchases greatly helps me in developing more stuff!
