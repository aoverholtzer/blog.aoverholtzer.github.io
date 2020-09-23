---
date: 2020-09-23 09:41
description: Doing availability checks with SwiftUI's declarative syntax can be a little messy. Here's a custom view modifier that can help.
---
# SwiftUI View Modifiers and `if #available`

## tl;dr

Here is a view modifier that lets you run arbitrary code before returning a modified view:

```swift
extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }
}
```

What is it good for? Why, platform availability checks!

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .modify {
                if #available(watchOS 7, *) {
                    $0.textCase(.uppercase)
                } else {
                    $0
                }
            }
    }
}

```

## Why do we need this?

iOS 14, watchOS 7, and macOS 11 have brought major updates to SwiftUI. If you have an app that supports older OS versions, then you probably very familiar with `#available`:

```swift
if #available(watchOS 7, *) {
    // the new hotness
} else {
    // old and busted
}
```

Unfortunately, doing availability checks with SwiftUI's declarative syntax can be a little messy. Let's look at an example for watchOS. 

Here's a very basic watchOS view, written for watchOS 6:

```swift
struct ContentView: View {
    var body: some View {
        List {
            ToolbarView()
            
            ForEach(0..<10) { i in
                NavigationLink(destination: DetailView(index: i)) {
                    Text("Button \(i)")
                }
            }
        }
    }
}
```

WatchOS 7 added support for toolbars on all platforms, which we should use instead of shoving ToolbarView() into the top of the List. 

In case you're not familiar with the `.toolbar()` view modifier, here is an implementation that does *not* support watchOS 6:

```swift
struct ContentView: View {
    var body: some View {
        List {
            ForEach(0..<10) { i in
                NavigationLink(destination: DetailView(index: i)) {
                    Text("Button \(i)")
                }
            }
        }
        .toolbar { // error: toolbar requries watchOS 7
            ToolbarView()
        }
    }
}
```

To also support watchOS 6, it would be nice if we could wrap the differences in `if #available` like so:

```swift
struct ContentView: View {
    var body: some View {
        List {
            if #available(watchOS 7, *) {
                // use .toolbar() below
            } else {
                ToolbarView()
            }
            
            ForEach(0..<10) { i in
                NavigationLink(destination: DetailView(index: i)) {
                    Text("Button \(i)")
                }
            }
        }
        if #available(watchOS 7, *) { // error
            .toolbar {
                ToolbarView()
            }
        }
    }
}
```

Alas, this code won't compile. The first use of `if #available` is good but the second — attempting to wrap the `.toolbar()` view modifier — is no good. We would need to wrap an `if-else` around the *entire* `List`, which means either duplicating a lot of code or refactoring our view. This is a simple example, but I'm sure you can imagine how ugly this can get for more complex views. 

Why isn't there a better way?!

## Inspiration: Conditional view modifier

You may have seen [Federico Zanetello's Conditional View Modifier](https://fivestars.blog/swiftui/conditional-modifiers.html), which takes a conditional and a closure as input:

```swift
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, 
                                 transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
```

This lets us *optionally* apply a view modifier, which is great for view modifiers that don't take any input:

```swift
Text("Button \(i)")
    .if(i < 5) { 
        $0.hidden() 
    }
```

Unfortunately, as Federico explains, this trick won't work for availability checks:

<blockquote>
<ul>
<li>Swift’s #available and @available cannot be passed as arguments in our if modifier</li>
<li>we can’t guarantee the compiler that our transform function would be applied only on iOS 14/13.4 and later</li>
</ul>
<p>If you find a way, I would love to know!</p>
</blockquote>

Well Federico, I found a way!

## Closure view modifier

```swift
extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }
}
```

My solution omits the conditional and applies `@ViewBuilder` to the closure, which will allow us to define our own `if-else` inside the closure:

```swift
struct ContentView: View {
    var body: some View {
        List {
            if #available(watchOS 7, *) {
                // use .toolbar() below
            } else {
                ToolbarView()
            }
            
            ForEach(0..<10) { i in
                NavigationLink(destination: DetailView(index: i)) {
                    Text("Button \(i)")
                        
                }
            }
        }
        .modify {
            if #available(watchOS 7, *) {
                $0.toolbar {
                    ToolbarView()
                }
            } else {
                $0
            }
        }
    }
}
```

That may not be pretty, but it works!

(If you find a more elegant solution, please [let me know](https://twitter.com/aoverholtzer).)
