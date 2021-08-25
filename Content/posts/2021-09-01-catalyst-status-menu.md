---
date: 2021-09-01 09:41
description: How to create a standalone “status menu” app and embed it in your Mac Catalyst app.
---
# Standalone Status Menu in a Mac Catalyst App

If you look up at the righthand side of a Mac’s menu bar, you’ll see a row of icons that are usually called *status menus*. Some status menus are provided by macOS, such as the Wi-Fi and Volume controls. But third-party apps can also create status menus to provide easy, always-available access to app features.

![Screenshot of a status menu, courtesy of https://support.apple.com/guide/mac-help/menu-bar-mchlp1446/mac](/images/status-menu-help.png)

In this post, I will walk you through creating a status menu app — a small AppKit app that runs separately from its parent app — and embedding it in a Mac Catalyst app. Let’s do it!

## Create the Status Menu

First we’ll make the status menu.

```swift
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
        
        ...
```

Etc.