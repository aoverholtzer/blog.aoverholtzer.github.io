---
date: 2021-09-27 09:41
description: Here are a few of the SwiftUI animation tips and tricks I’ve learned while building my kid-friendly timer app Time’s Up! Timer.
image: /images/todo

---

<figure><img src="/images/times-up-promo.jpg" alt="Screenshot of a Time’s Up! Timer" /></figure>

# SwiftUI Animation Lessons From Building “Time’s Up! Timer”

I recently launched **[Time’s Up! Timer](https://overdesigned.net/timesup/)**, a kid-friendly timer app for iOS, macOS, and tvOS. It’s a SwiftUI app that makes heavy use of animations, so I thought I’d share a few of the SwiftUI animation tips and tricks I’ve learned building it.


## Use `animation(_:value:)` instead of `.animation(_:)`

Let’s start with the simplest lesson: always use `animation(_:value:)` for implicit animations. Unlike the simpler `.animation(_:)` modifier, this also requires an `Equatable` value parameter and the animation will *only* be applied when that value changes. Without this, the animation may run when other properties change or during animated transitions.

Here’s an excerpt from the code for my timer view, which draws a clock face and a hand. The hand animates when its `angle` changes, thanks to `animation(.interactiveSpring(), value: angle)`.

```swift
struct TimerClockfaceView: View {
    @State var angle: Angle
    
    var body: some View {
        ZStack {
            makeFace()
        
            makeHand()
                .rotationEffect(angle)
                .animation(.interactiveSpring(), value: angle)
        }
    }
}
```

The value-less version of `.animation(_:)` is deprecated as of iOS 15 / macOS 12, so I guess Apple agrees: always use `animation(_:value:)`.


## Respect your user’s Reduce Motion setting

Settings &rarr; Accessibility &rarr; Motion &rarr; Reduce Motion.

```swift
struct TimerClockfaceView: View {
    @State var angle: Angle
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            makeFace()
            
            makeHand()
                .rotationEffect(angle)
                .animation(reduceMotion ? .default : .interactiveSpring(),
                           value: angle)
        }
    }
}
```

## Use `withTransaction` to override implicit animations

Here’s a snippet of code from my main view, which shows the timer, the remaining time as `Text`, and a **Reset** button.

```swift
struct ContentView: View {
    @StateObject var timer: TimesUpTimer
    
    var body: some View {
        VStack {
            Text(timer.remainingTimeString)
                .font(.title)
            TimerClockfaceView()
                .aspectRatio(1, contentMode: .fit)
            Button("Reset") {
                timer.reset()
            }
        }
    }
}
```

And here’s a screenshot of what happens when I tap **Reset**.


Remember we set an implicit animation on our hand, so the rotation of the hand will animate using `.interactiveSpring()` when the **Reset** button is tapped. I think this is way too bouncy to use with **Reset**, so let’s override the implicit animation.

You might think using an explicit `withAnimation` is the answer…

```swift
struct ContentView: View {
    @StateObject var timer: TimesUpTimer
    
    var body: some View {
    	...
        Button("Reset") {
            withAnimation(.default) {
                timer.reset()
            }
        }
    }
}
```

… but that doesn’t *override* the spring animation. The hand still bounces into place.

The solution is `withTransaction`, which is similar to `withAnimation` except it takes a `Transaction` object. A `Transaction` is basically an *animation context*, if you’ve worked with those elsewhere. 

```swift
struct ContentView: View {
    @StateObject var timer: TimesUpTimer
    
    var body: some View {
        ...
        Button("Reset") {
            var transaction = Transaction(animation: .default)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                timer.reset()
            }
        }
    }
}
```

Here we create a Transaction with our desired animation (we’ll use a boring old `.default` animation). Then we set the Transaction’s `disablesAnimations` property to true, which tells it to disable all implicit animations on the affected views, e.g. our hand animation. Finally, we call `withTransaction(_:_:)` like we would `withAnimation(_:_:)`, providing our transaction and a closure to execute.


## Use `transaction(_:)` to override explicit animations

Now something unexpected is happening: our `Text` view is animating when we tap **Reset**.

```swift
struct ContentView: View {
    @StateObject var timer: TimesUpTimer
    
    var body: some View {
    	Text(timer.remainingTimeString)
    	    .transaction { transaction in
    	        transaction.animation = .none
    	    }
    	...
    }
}
```


## Always test device rotation

Your SwiftUI views will animate to their new sizes when you rotate your iPhone or iPad, and this may produce some undesirable results. I recommend testing device rotation in the simulator with **Debug &rarr; Slow Animations** enabled so you can see exactly what’s happening.

In my app, rotating the device seems to resize the timer face and hand differently. I’ll fix this by applying `drawingGroup()` to the `ZStack` that containing those views.

```swift
struct TimerClockfaceView: View {
    @State var angle: Angle
    
    var body: some View {
        ZStack {
            makeFace()
            
            makeHand()
                .rotationEffect(angle)
                .animation(.interactiveSpring(), value: angle)
        }
        .drawingGroup()
    }
}
```

## For animation-heavy Mac apps, consider Catalyst

We shouldn’t need to use it, and there are some *serious* downsides — e.g., `.toolbar` won’t give you Mac toolbars, `.commands` don’t work at all — but for whatever reason, SwiftUI animations run much, *much* better in Catalyst.


## Learn more

I recommend SwiftUI Lab’s <strike>three</strike>*five* part series.

And if any of these tips have helped you, please check out **[Time’s Up! Timer](https://overdesigned.net/timesup/)** and leave a nice review!