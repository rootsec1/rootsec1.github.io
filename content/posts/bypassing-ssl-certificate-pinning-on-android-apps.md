+++ 
date = 2021-12-22T22:21:22+05:30
title = "Bypassing SSL certificate pinning on Android apps using Frida"
description = "SSL certificate pinning is a security mechanism implemented in many Android apps to ensure secure communication with designated servers. It validates the server's identity by comparing its presented certificate with a pre-defined set of trusted certificates. However, during security assessments or debugging scenarios, it may be necessary to bypass SSL certificate pinning to analyze the app's network traffic. In this tutorial, we will explore how to bypass SSL certificate pinning using Burp Suite and Frida."
slug = ""
authors = []
tags = ["frida", "android", "security", "burpsuite"]
categories = []
externalLink = ""
series = []
+++

SSL certificate pinning is a security mechanism implemented in many Android apps to ensure secure communication with designated servers. It validates the server's identity by comparing its presented certificate with a pre-defined set of trusted certificates. However, during security assessments or debugging scenarios, it may be necessary to bypass SSL certificate pinning to analyze the app's network traffic. In this tutorial, we will explore how to bypass SSL certificate pinning using Burp Suite and Frida.

## Prerequisites

Before we begin, make sure you have the following:

- Android device or emulator
- Burp Suite (Proxy tool for intercepting and modifying network traffic)
- Frida (Dynamic instrumentation toolkit)

## Step 1: Setting Up Burp Suite

Burp Suite acts as a proxy between the Android device and the target server. Follow these steps to configure Burp Suite:

- Configure your Android device or emulator to use Burp Suite as a proxy. **Navigate to Settings -> Wi-Fi -> Modify Network -> Proxy -> Manual** and set the host to the IP address of your Burp Suite proxy machine and the port to the Burp Suite proxy port (e.g., 127.0.0.1:8080).

- Install the Burp Suite CA certificate on your Android device or emulator. In Burp Suite, go to **Proxy -> Options -> Import / Export CA Certificate** -> Certificate in DER format and save the certificate.

- Import the Burp Suite CA certificate on your Android device or emulator. Go to **Settings -> Security -> Install from storage** and select the Burp Suite certificate.

## Step 2: Installing and Configuring Frida

Frida is a powerful dynamic instrumentation toolkit that allows us to modify the behavior of the target Android app. Here's how to install and configure Frida:

- Install Frida on your machine using the package manager of your choice. Open a terminal and run the following command:

```shell
pip install frida
```

- Install the Frida server on your Android device or emulator using the Frida CLI tool. Run the following command in the terminal:

```shell
frida --device=<device_name> --no-pause -U -f <package_name> --no-pause
```

Replace `<device_name>` with the name of your connected device or emulator and `<package_name>` with the package name of the target app.

## Step 3: Bypassing SSL Certificate Pinning with Frida

To bypass SSL certificate pinning, we will use Frida to modify the behavior of the SSL pinning check in the target Android application. We need to identify the class responsible for SSL pinning and override the method that performs the pinning check. Here's an example Frida script to achieve this:

{{< gist rootsec1 352a41215be83678b7a80944ff5433a9 >}}

## Step 4: Verifying SSL Certificate Pinning Bypass

Now that we have set up Burp Suite, Frida, and the SSL pinning bypass script, let's verify if the SSL certificate pinning is successfully bypassed. Follow these steps:

- Start Burp Suite and ensure that it is intercepting the network traffic from the Android device or emulator.
- Launch the target Android app on the device or emulator.
- In the terminal, run the Frida script using the Frida CLI tool:

```shell
frida --device=<device_name> -U -f <package_name> -l <frida_script.js>
```

Replace `<device_name>` with the name of your connected device or emulator, `<package_name>` with the package name of the target app, and `<frida_script.js>` with the filename of the Frida script.

- Observe the Burp Suite proxy log. If SSL certificate pinning is successfully bypassed, you will see the decrypted network traffic from the target app in Burp Suite.

## Conclusion

In this tutorial, we explored how to bypass SSL certificate pinning in Android apps using Burp Suite and Frida. By intercepting and modifying network traffic, we can analyze and understand the app's communication with servers. However, it's important to use this technique responsibly and only in authorized scenarios. Always ensure that you have proper permissions and legal rights to perform such actions.
