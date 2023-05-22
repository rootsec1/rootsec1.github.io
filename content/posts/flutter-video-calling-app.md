+++ 
date = 2020-06-29T21:48:30+05:30
title = "Building a Multi-Participant Video Calling App with Flutter"
description = "Agora.io provides a comprehensive real-time engagement platform that includes audio, video, and messaging solutions. Their SDKs offer developers the tools and infrastructure to build robust and scalable applications with real-time communication capabilities."
slug = ""
authors = []
tags = ["flutter", "mobile-app-dev", "video-call"]
categories = []
externalLink = ""
series = []
+++

Flutter, the cross-platform development framework, coupled with the powerful Agora.io SDK, offers an excellent platform to build multi-participant video calling applications. In this blog post, we will explore how to create a multi-participant video calling app using Flutter and the Agora.io SDK, enabling seamless and immersive real-time communication.

## Introduction to Agora.io SDK

Agora.io provides a comprehensive real-time engagement platform that includes audio, video, and messaging solutions. Their SDKs offer developers the tools and infrastructure to build robust and scalable applications with real-time communication capabilities.

## Setting Up the Project

To get started, follow these steps:

Set up a new Flutter project:

```shell
flutter create video_call_app
cd video_call_app
```

Add the Agora Flutter SDK dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  agora_rtc_engine: ^4.0.0
```

Import the Agora Flutter SDK package:

```dart
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
```

## Initializing the Agora Engine

Before we can establish a video call, we need to initialize the Agora engine. Use the following code snippet to initialize the engine:

```dart
class VideoCallPage extends StatefulWidget {
  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  Future<void> initializeAgora() async {
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig(appId: '<YOUR_APP_ID>'));
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);
    await _engine.joinChannel('<YOUR_TOKEN>', 'channel_name', null, 0);
  }

  @override
  void dispose() {
    _engine.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call'),
      ),
      body: Center(
        child: Stack(
          children: [
            // Local video view
            RtcLocalView.SurfaceView(),
          ],
        ),
      ),
    );
  }
}
```

Replace `<YOUR_APP_ID>` with your Agora App ID and `<YOUR_TOKEN>` with the generated token for authentication.

## Displaying Remote Video Views

To display the remote video views of the participants in the video call, use the following code snippet:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Video Call'),
    ),
    body: Center(
      child: Stack(
        children: [
          // Local video view
          RtcLocalView.SurfaceView(),
          // Remote video view
          RtcRemoteView.SurfaceView(uid: uid),
        ],
      ),
    ),
  );
}
```

Here, uid represents the unique user ID of the remote participant.

## Controlling Video Streams

You can control the video streams by muting or un-muting the local and remote video feeds. Here are two code snippets that demonstrate this functionality:

```dart
// Muting the local video
await _engine.muteLocalVideoStream(true);

// Unmuting the local video
await _engine.muteLocalVideoStream(false);

// Muting the remote video
await _engine.muteRemoteVideoStream(uid, true);

// Unmuting the remote video
await _engine.muteRemoteVideoStream(uid, false);
```
