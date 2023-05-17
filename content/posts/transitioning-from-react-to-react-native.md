+++ 
date = 2019-06-07T23:32:28+05:30
title = "Transitioning from React to React Native"
description = "You already use React to build web apps. You’ve heard about this thing called React Native and want to play with it… or even build a client project with it."
slug = ""
tags = ["react", "react-native", "jsx", "javascript", "mobile-app-dev"]
externalLink = ""
series = []
+++

# How do you go from React to React Native?

You already use React to build web apps.
You've heard about this thing called React Native and want to play with it... or even build a client project with it.

And you probably have many questions, one of which is:

> "Would I get lost if I don't already know how to build apps with Swift/Java?"

It depends on the app, but the quick answer is No, you won't get lost. For the most part, things will work just like in React. You have some div-like components, which you can style with something like CSS. You have the same state and props mechanisms.

## When might you need to know some Swift/Java?

If you plan on writing a full-featured mobile game, React Native will probably be out of consideration. If you need to write some native code, whether to optimize performance, or access native mobile APIs, knowing Swift, Objective-C, or Java will come in handy. Mostly, however, you are not going to need any knowledge of any native language.

But mobile apps often need to make use of some native APIs... do I have to learn Swift if I need Touch ID support? Even when you *do* have to make use of some native functionality, chances are, there's a React Native wrapper for that already!

React Native comes bundled with some native wrappers:

- [`ImagePickerIOS`](https://facebook.github.io/react-native/docs/imagepickerios.html)
- [`Alert`](https://facebook.github.io/react-native/docs/alert.html)

And there are npm packages for things like [Touch ID](https://github.com/naoufal/react-native-touch-id) and many more.

Which sometimes can require some fiddling around in Xcode or editing Gradle files (no worries if you have no idea what these are), but their readmes usually give clear step by step guidance on what to do.

In most cases, running `react-native link <package-name>` will do that for you, automatically!

What about distribution?

While the first-hand experience of Xcode, iTunes Connect and things in-between would be beneficial, you can follow the steps to submit your app even *without* knowing any Swift or Java.

While we're at it...

## React vs. React Native

Here is a quick run-down of differences between React and React Native:

- Most of React knowledge is transferrable to React Native.

  State, props, everything works the same way as you'd expect it to.

- `<View>` instead of `<div>`.

  A [different component for text input](https://facebook.github.io/react-native/docs/handling-text-input.html).

- Many of CSS properties are supported by React Native.

  You have flexbox and absolute positioning and colors and borders and so on.

  You don't get CSS transitions, though. But React Native *does* come with a [very powerful API for animations](https://goshakkk.name/react-native-animated-building-blocks/).

  Also --- no media queries.

- There are no class names, however. You have to pass in the styles directly to the components: `<View style={{ margin: 10 }}>`.

- `fetch` works as you'd expect it to.

- [`AsyncStorage`](https://facebook.github.io/react-native/docs/asyncstorage.html) in place of `localStorage`.

- Android support can be quirky. `overflow: visible` is not supported, and until recently, there were `zIndex` issues.

</div>
