---
date: 2021-09-01 09:41
description: How to create a standalone “status menu” app and embed it in your Mac Catalyst app.
---
# Standalone Status Menu in a Mac Catalyst App

<figure><img src="/images/cheatsheet-menu.jpg" srcset="/images/cheatsheet-menu.jpg 2x" alt="Screenshot of Cheatsheet’s status menu" /></figure>

I make a somewhat successful app called [Cheatsheet](https://itunes.apple.com/app/id1468213484), which is available for iOS, watchOS, and — thanks to Catalyst — macOS. Cheatsheet makes it easy to get to your notes from anywhere, which means widgets and custom keyboards on iOS and complications on watchOS. On macOS, Cheatsheet has a *status menu app*. 

Embedding a status menu app in a Catalyst app is a bit of a trick, and [apparently](https://twitter.com/stroughtonsmith/status/1429970709791522817?ref_src=twsrc%5Etfw) folks want to know how I did it. Here’s how!


## What is a Status Menu?

<figure><img src="/images/status-menu-help.png" srcset="/images/status-menu-help.png 2x" alt="Screenshot of a status menu, courtesy of https://support.apple.com/guide/mac-help/menu-bar-mchlp1446/mac" /></figure>

Look up at the righthand side of a Mac’s menu bar and you’ll see a row of icons called **status menus**. Several status menus are provided by macOS, such as the Wi-Fi and Volume controls. Third-party apps can also create status menus to provide easy, always-available access to app features.

In this post, I will walk you through creating a status menu app — a small AppKit app that runs separately from its parent app — and embedding it in a Mac Catalyst app. The parent app will have a checkbox that shows or hides the status menu, and clicking the status menu icon will show a popover. Let’s do it!

<figure><img src="/images/status-menu-example.jpg" alt="Screenshot of my sample app and status menu" /></figure>

## Create the Status Menu App

Let’s start with the fun part: building the status menu app. 

Select your project and add a new **Mac App** target.

<figure><img src="/images/menu-mac-app.png" srcset="/images/menu-mac-app.png 2x" alt="Screenshot of a Xcode’s Add Target window" /></figure>

Then in the “Choose options for your new target” screen, select **Interface: SwiftUI** and **Life Cycle: AppKit App Delegate**. We need the AppDelegate so we can create a windowless app, which is *technically* possible with the SwiftUI life cycle but it’s a bit of a [hack](https://github.com/zaferarican/menubarpopoverswiftui2).

<figure><img src="/images/menu-life-cycle.png" srcset="/images/menu-life-cycle.png 2x" alt="Screenshot of a Xcode’s Choose options for your new target window" /></figure>

Enter a **Product Name** and click **Finish**. 

Now select your new target and switch to its **Info** tab. Add a new property: **Application is agent (UIElement)**. Set its value to **YES**. What does this cryptically-named property do? It tells macOS that your app should be run as an “agent”, which means it won’t appear in the Dock or the Force Quit window.

<figure><img src="/images/menu-uielement.png" srcset="/images/menu-uielement.png 2x" alt="Screenshot of the Info tab of our new target in Xcode" /></figure>

With that out of the way, we’re ready to code! In the project navigator, open your new target’s **AppDelegate.swift** and look for `applicationDidFinishLaunching`. It will contain a bunch of code creating a window — delete all of that and replace it with this:

```swift
// AppDelegate.swift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem : NSStatusItem!
    var popover : NSPopover!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "tornado", accessibilityDescription: nil)
            statusButton.action = #selector(togglePopover(sender:))
            statusButton.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        let content = NSHostingController(rootView: ContentView())
        popover.contentViewController = content
        popover.contentSize = content.view.intrinsicContentSize
        popover.behavior = .transient
        popover.animates = false
    }
}
```

This code does two things:

1. Creates a new `NSStatusItem` in the system status bar. Status items can have either a drop-down menu or a button; we’ll create a button with a tornado icon that displays a popover when clicked.
2. Creates an `NSPopover` with a SwiftUI view. We set the popover’s `behavior` to `.transient`, which means the popover closes if you click anywhere outside of it, and `animates` to *false* because I find the default open/close animations to be frustratingly slow. We also set the popover’s `contentSize` here using the SwiftUI view’s `intrinsicContentSize` — ideally, SwiftUI would size the popover for us, but in my testing it seems we need to set the `contentSize` before we try to show the popover.

Now all we need is to add `togglePopover(sender:)` to **AppDelegate.swift**:

```swift
// AppDelegate.swift

@objc func togglePopover(sender: Any?) {
    guard let statusButton = statusItem.button else { return }
    
    if popover.isShown {
        popover.performClose(sender)
    } else {
        popover.show(relativeTo: statusButton.bounds,
                     of: statusButton,
                     preferredEdge: NSRectEdge.maxY)
    }
}
```

This shows the popover relative to the status item, or closes the popover if it’s already showing.

At this point, you should be able to **Run** your status menu target. The little tornado icon should appear in the menu bar, and clicking it should show a popover.

## Add to Catalyst Project

Now let’s switch back to our main target, which is our Mac Catalyst app. How do we embed our little status menu app into our main app?

1. Add menu’s product to dependencies
2. add “copy” build stage

## Add Controls

1. Define SMLoginItemSetEnabled in bridging header
2. Create StatusMenuHelper
3. Wire-up UI

And we’re done!


<blockquote class="twitter-tweet" data-dnt="true"><p lang="en" dir="ltr">that’s a good question for <a href="https://twitter.com/aoverholtzer?ref_src=twsrc%5Etfw">@aoverholtzer</a>, who’s done exactly that in <a href="https://twitter.com/cheatsheet_app?ref_src=twsrc%5Etfw">@cheatsheet_app</a></p>&mdash; Steve Troughton-Smith (@stroughtonsmith) <a href="https://twitter.com/stroughtonsmith/status/1429970709791522817?ref_src=twsrc%5Etfw">August 24, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>