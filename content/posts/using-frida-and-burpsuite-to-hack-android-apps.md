+++ 
date = 2020-07-13T21:56:36+05:30
title = "Hacking Android apps using frida and burpsuite"
description = "Frida is an open-source dynamic instrumentation toolkit that allows developers and security researchers to inject JavaScript or Python scripts into running processes. With Frida, we can dynamically intercept function calls, modify data, and perform various actions to analyze the behavior of an app at runtime. Frida supports multiple platforms, including Android, iOS, Windows, macOS, and Linux."
slug = ""
authors = []
tags = ["security", "android", "mobile-app-dev"]
categories = []
externalLink = ""
series = []
+++

In the field of mobile application security, dynamic analysis plays a crucial role in understanding the behavior of an app during runtime. By monitoring and manipulating an app's execution, we can uncover vulnerabilities, analyze network communication, and gain valuable insights into its inner workings. In this blog post, we will explore how to use Frida, a powerful dynamic instrumentation toolkit, to perform dynamic analysis on Android apps. We will also examine network requests using Burp Suite, a popular web proxy tool. Let's dive in!

## Introduction to Frida

Frida is an open-source dynamic instrumentation toolkit that allows developers and security researchers to inject JavaScript or Python scripts into running processes. With Frida, we can dynamically intercept function calls, modify data, and perform various actions to analyze the behavior of an app at runtime. Frida supports multiple platforms, including Android, iOS, Windows, macOS, and Linux.

## Setting Up the Environment

To get started, follow these steps:

- Install Frida tools:

```shell
pip install frida-tools
```

- Set up an Android device or emulator.
- Install the Frida server on the target Android device:

```shell
adb push frida-server /data/local/tmp/
adb shell chmod 755 /data/local/tmp/frida-server
adb shell /data/local/tmp/frida-server &
```

## Dynamic Analysis with Frida

Now that our environment is set up, let's perform dynamic analysis on an Android app. We'll start by hooking into specific functions and inspecting method arguments. This extended Frida script adds code to bypass SSL certificate pinning in the target app. It dynamically registers a custom `TrustManager` implementation that ignores certificate validation, allowing the interception and analysis of network requests even when SSL certificate pinning is enabled. With this added functionality, you can perform comprehensive analysis of network traffic in the app, including encrypted communication.

{{< gist rootsec1 352a41215be83678b7a80944ff5433a9 >}}

Save the above script as `frida_script.js`. Now, let's run the script with Frida:

```shell
frida -U -l frida_script.js com.example.app
```

Frida will attach to the target app, hook the specified methods, and print the intercepted information to the console.

## Examining Network Requests with Burp Suite

In addition to dynamic analysis, we can intercept and examine network requests made by the target app using Burp Suite. Here's how to set it up:

- Set up Burp Suite and configure the proxy settings on your device or emulator to point to Burp Suite's proxy.
- Obtain the Burp Suite CA certificate and install it on the device or emulator to enable SSL interception.
- Launch Burp Suite and configure the proxy listener.
- Start the Frida server on the Android device:

```shell
adb shell /data/local/tmp/frida-server &
```

- Run the Frida script to hook into the network-related classes and methods (or just get root access):

```javascript
// frida_network_script.js
Java.perform(function () {
  var targetClass = Java.use("com.example.app.NetworkClass");

  // Hooking a network method
  targetClass.sendRequest.implementation = function (url, data) {
    var request = "URL: " + url + "\n";
    request += "Data: " + data + "\n";

    // Forward the intercepted request to Burp Suite
    send(request);

    // Call the original method
    return this.sendRequest(url, data);
  };
});
```

Save the above script as `frida_network_script.js`. Run the script with Frida:

```shell
frida -U -l frida_network_script.js com.example.app
```

Now, all network requests made by the target app will be intercepted by Frida and forwarded to Burp Suite for analysis. By combining Frida with tools like Burp Suite, we can gain valuable insights into an app's behavior, uncover vulnerabilities, and analyze network communication.
