---
date: 2021-09-27 09:41
description: Here are a few of the SwiftUI animation tips and tricks I’ve learned while building my kid-friendly timer app Time’s Up! Timer.
image: /images/todo

---

# SwiftUI Animation Tips & Tricks

Here are a few of the SwiftUI animation tips and tricks I’ve learned while building **Time’s Up! Timer**, my kid-friendly timer app for iOS, macOS, and tvOS.

## Always Use `animation(_:value:)`

I’m sure we’ve all used SwiftUI’s implicit animation modifier `.animation(_:)`, but I recommend using `animation(_:value:)` instead. This version applies the animation *only* when the specified `value` changes. Otherwise you may get animations you didn’t intend.

Here’s the code for my timer, which has a face and a hand. The hand animates when its `angle` changes.

```swift
// TimerClockface.swift

var body: some View {
    ZStack {
        makeFace()
        
        makeHand()
            .rotationEffect(angle)
            .animation(.customSpring, value: angle)
    }
}

extension Animation {
    static var customSpring: Animation {
        return .interactiveSpring(response: 0.2,
                                  dampingFraction: 0.4)
    }
}
```

The value-less version of `.animation(_:)` is actually deprecated as of iOS 15 / macOS 12, so it seems Apple agrees: always use `animation(_:value:)`.


## Respect Your User’s “Reduce Motion” Setting

Settings &rarr; Accessibility &rarr; Motion &rarr; Reduce Motion.

```swift
// TimerClockface.swift

@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    ZStack {
        makeFace()
        
        makeHand()
            .rotationEffect(angle)
            .animation(reduceMotion ? .default : .customSpring,
                       value: angle)
    }
}
```

## Use `withTransaction` to Override Implicit Animations

```swift
// ContentView.swift

var body: some View {
    VStack {
        Text(remainingTimeString)
            .font(.title)
        TimerClockface()
            .aspectRatio(1, contentMode: .fit)
        Button("Reset") {
            timer.reset()
        }
        .buttonStyle(.bordered)
    }
}
```

Remember we have set `.animation(.customSpring, value: angle)` on our hand, which means the movement of the hand will animate when the Reset button is tapped. Unfortunately my `.customSpring` animation is way too bouncy, so how can we override it?

You might think using an explicit `withAnimation` is the answer…

```swift
// ContentView.swift

Button("Reset") {
    withAnimation(.default) {
        timer.reset()
    }
}
```

… but that doesn’t *override* the spring animation. The hand still bounces into place. 

The solution is `withTransaction`, which is similar to `withAnimation` except it takes a `Transaction` object.

```swift
// ContentView.swift

Button("Reset") {
    var transaction = Transaction(animation: .default)
    transaction.disablesAnimations = true
    withTransaction(transaction) {
        timer.reset()
    }
}
```

A `Transaction` is basically an *animation context*, if you’ve worked with those elsewhere. 

First we create a Transaction with our desired animation (we’ll use a boring old `.default` animation). Then we set the Transaction’s `disablesAnimations` property to true, which tells it to override any implicit animations on the affected views (which is what we want). Then we call `withTransaction(_:_:)` exactly like we would `withAnimation(_:_:)`, providing our transaction and a closure to execute.


## Use `transaction(_:)` to Override Explicit Animations

Now something unexpected is happening: our `Text` view is animating when we tap Reset.

```swift
// ContentView.swift

Text(remainingTimeString)
    .transaction { transaction in
        transaction.animation = .none
    }
```


## Always Test Device Rotation

Your SwiftUI views will animate to their new sizes when you rotate your device, and this may produce some undesirable results. I recommend testing device rotation in the simulator with Debug &rarr; Slow Animations enabled so you can see exactly what’s happening.

In my app, rotating the device seems to animate the timer face and hand differently. We can fix this by applying `drawingGroup()` to the `ZStack` that contains both the face and hand.

```swift
// TimerClockface.swift

var body: some View {
    ZStack {
        makeFace()
        
        makeHand()
            .rotationEffect(angle)
            .animation(.customSpring, value: angle)
    }
    .drawingGroup()
}
```

## For Animation-Heavy Mac Apps, Consider Catalyst

We shouldn’t need to use it, and there are some *serious* downsides — e.g., `.toolbar` won’t give you Mac toolbars, `.commands` don’t work at all — but for whatever reason, SwiftUI animations run much, *much* better in Catalyst.

## Learn More

I recommend SwiftUI Lab’s <strike>three</strike>*five* part series.

And if any of these tips have helped you, please check out **Time’s Up! Timer** and leave a nice review!