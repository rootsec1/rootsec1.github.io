+++ 
date = 2020-02-06T00:48:17+05:30
title = "Mobile app for Indian railways"
description = "Award winning mobile app that we built for Smart India Hackathon 2018 to address problems with public announcement systems"
slug = ""
authors = []
tags = ["mobile-app-dev", "android", "nodejs"]
categories = []
externalLink = ""
series = []
+++

# Mobile App to Address Public announcement issues and Loss of belongings in Indian Railway stations

[android app screen recording](https://drive.google.com/file/d/129ABXPT-a7IBICQmPboKRRnj6eDofuXT/view?usp=sharing)

[backend code repo](https://github.com/rootsec1/electric_sheep_server)  
[android app code repo](https://github.com/rootsec1/congenial-dollop)

## Introduction

In a country as populous as India, public announcements play a crucial role in disseminating important information to the masses. However, issues such as limited accessibility, technical challenges, and communication gaps can hinder the effectiveness of public announcements. As participants in a SIH-2018, our team took up the challenge of developing a mobile app to address these issues and ensure that critical notifications reach the intended recipients efficiently. In this blog post, we will walk you through the key modules and features of our app.

## Online Radio with Railway Station Notifications

The first module of our mobile app tackled the problem of inadequate public announcement systems at railway stations. We integrated an online radio feature that provided a list of notifications from the nearest railway station. Leveraging internet connectivity, users could access the app and stay updated with the latest notifications. Whether it was train delays, platform changes, or emergency announcements, commuters and passengers could receive timely information and make informed decisions about their travel plans. By enhancing the accessibility of railway station notifications, we aimed to streamline the communication process and improve the overall travel experience.

## BLE Beacon Functionality for Belonging Tracking

Another significant module of our app focused on addressing the common issue of losing belongings in crowded places. Before airtags came into picture, we implemented BLE (Bluetooth Low Energy) beacon functionality using Google's Nearby API. Users could attach small BLE beacons to their belongings, such as bags, wallets, or keys. The app would then track the proximity of these belongings within a certain range. If the user moved away from their belongings or left them behind, the app would send real-time updates and notifications. This feature aimed to provide peace of mind and reduce the risk of loss or misplacement of valuable items, especially in crowded public spaces.

## Local FM Transmitter for Enhanced Accessibility

We recognized that not all individuals have access to smartphones or may face challenges in using mobile apps. To ensure that critical notifications reach a wider audience, we integrated a local FM transmitter module in our app. This feature allowed important announcements to be broadcasted on a local FM frequency. By leveraging FM radio technology, we aimed to bridge the digital divide and cater to the needs of technically challenged individuals. Whether it was safety alerts, weather updates, or emergency instructions, this module ensured that vital information reached everyone, regardless of their technical proficiency or smartphone accessibility.

## Tech Stack and Implementation

To bring our vision to life, we utilized a combination of front-end and back-end technologies. The front-end of our mobile app was developed for Android using Java, allowing us to provide a user-friendly interface and seamless navigation. For the back-end, we leveraged Python and the Flask framework. Flask provided a flexible and lightweight foundation for our API development, enabling smooth communication between the front-end and back-end components.


