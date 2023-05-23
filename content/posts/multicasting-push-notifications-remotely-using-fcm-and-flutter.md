+++ 
date = 2021-05-15T22:13:17+05:30
title = "Multi-casting push notifications using FCM and Flutter"
description = "Firebase Cloud Messaging (FCM) is a powerful platform for sending push notifications to mobile devices. In this technical blog post, we will explore how to trigger FCM messages with payloads and image URLs to multiple devices from a Python backend. We will then receive these messages in a Flutter app and render them as notifications using the necessary plugins."
slug = ""
authors = []
tags = ["flutter", "python", "firebase"]
categories = []
externalLink = ""
series = []
+++

Firebase Cloud Messaging (FCM) is a powerful platform for sending push notifications to mobile devices. In this technical blog post, we will explore how to trigger FCM messages with payloads and image URLs to multiple devices from a Python backend. We will then receive these messages in a Flutter app and render them as notifications using the necessary plugins. Let's dive deep into the integration process!

## Setting Up FCM

Before we begin, make sure you have set up FCM in your Firebase project. Obtain the necessary credentials, such as the server key and sender ID, which will be required in the integration.

## Python Backend Integration

First, let's look at how to trigger FCM messages from a Python backend. We'll be using the `firebase-admin` library to interact with FCM. Here's an example code snippet:

```python
import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging

# Initialize Firebase Admin SDK
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)

# Trigger FCM message to multiple devices
def send_fcm_message(device_tokens, title, body, image_url):
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data={'image_url': image_url},
        tokens=device_tokens
    )
    response = messaging.send_multicast(message)
    print('FCM message sent successfully:', response.success_count, 'tokens')
```

In this code snippet, we initialize the Firebase Admin SDK with the appropriate credentials. The `send_fcm_message` function takes a list of device tokens, a title, a body, and an optional image URL. It creates a `MulticastMessage` object with the notification details and additional data. Finally, we use the `messaging.send_multicast` method to send the message to multiple devices.

## Flutter App Integration

Next, let's explore how to receive FCM messages in a Flutter app and render them as notifications. We'll be using the `firebase_messaging` and `flutter_local_notifications` plugins. Here's an example code snippet:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize Firebase Messaging
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

// Initialize Local Notifications
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Configure Local Notifications
void configureLocalNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  _flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Configure Firebase Messaging
void configureFirebaseMessaging() {
  _firebaseMessaging.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final String imageUrl = message.data['image_url'];

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'your_channel_id', 'your_channel_name', 'your_channel_description',
            importance: Importance.max, priority: Priority.high);

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: imageUrl,
    );
  });
}
```

In this Dart code snippet, we initialize the Firebase Messaging and Local Notifications plugins. The `configureLocalNotifications` function sets up the local notifications plugin, and the `configureFirebaseMessaging` function configures the Firebase Messaging plugin. We request permission to receive notifications and listen for incoming messages using `FirebaseMessaging.onMessage`. When a message is received, we extract the image URL from the data payload and display a local notification using `flutter_local_notifications`.

## Conclusion

In this technical blog post, we explored the integration of FCM messages with a Python backend and a Flutter app. We learned how to trigger FCM messages with payloads and image URLs from the backend using the `firebase-admin` library. We also saw how to receive these messages in a Flutter app and render them as notifications using the `firebase_messaging` and `flutter_local_notifications` plugins.

By following the steps outlined in this blog post, you can implement robust push notification functionality in your Python-Flutter application. Leveraging FCM allows you to engage your users with timely and relevant information, enhancing the overall user experience.
