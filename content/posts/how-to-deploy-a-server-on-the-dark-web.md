+++ 
date = 2019-06-14T23:44:17+05:30
title = "How to deploy a server on the dark web"
description = "This blog post focuses more how to deploy a server using the onion routing protocal over tor and not an introduction to how Tor works"
slug = ""
authors = []
tags = ["dark-web", "tor", "python", "security", "backend-engineering"]
categories = []
externalLink = ""
series = []
+++

The Tor browser can be downloaded from [here](https://www.torproject.org/projects/torbrowser.html.en).
Once installed, you can open the browser, and it will automatically connect to the Tor network.
You can view your route through the Tor network by clicking the drop-down arrow next to the onion icon in the upper left part of the window.

Tor has been protecting people’s identity from being uncovered and allowed them to express their ideas over the internet anonymously.
A significant [number of people](https://metrics.torproject.org/) misuse this network to visit banned websites, download sexual content by bypassing filters and most importantly, tor is used by hackers to attack organizations without revealing their identity.
An example for the latter was the [Skynet Botnet](https://blog.rapid7.com/2012/12/06/skynet-a-tor-powered-botnet-straight-from-reddit/) in which the Command and Control servers (C&and;C) were hidden behind the Tor network.

## How Does TOR Work ?

Tor consists of a network of relay servers which are run by volunteers all over the world. When a user connects to the Tor network using Tor client/Tor enabled browser, a path is created from the user to the destination server to which the user needs to connect. This path consists of three relay servers called Entry Node, Middle Node and Exit Node.
All the requests the sender sends to the destination through the Tor network are relayed through this pre-built path and the responses from the destination returns back to the sender through the same path. All the data going through the Tor network is completely encrypted such that nobody who intercepts the communication have no clue who the sender is. But, if one sniffs outgoing link from the exit node can capture the data transmitted both sides, but anonymity is still secured
When you download Tor from the website, you can run Tor as a local [SOCKS](https://en.wikipedia.org/wiki/SOCKS) proxy in you computer. When your browser is configured to use that local SOCKS proxy, you can browser internet with that browser through the tor network. You can configure many applications to use this SOCKS proxy and use them through Tor network, these applications include web browsers, download manager software, bittorrent clients etc.

**However, this blog post focuses more how to deploy a server using the onion routing protocal over tor and not an introduction to how Tor works.
You can find the exact specifics of how tor works [here](https://2019.www.torproject.org/about/overview#thesolution). Moving on.**

## Section 1 - Running a simple python server

The first step in configuring a Tor server will be setting up a way to serve HTTP content, just the same as a regular web server might. While we might choose to run a conventional web server at 0.0.0.0 so that it becomes accessible to the internet as a whole by its IP, we can bind our local server environment to 127.0.0.1 to ensure that it will be accessible only locally and through Tor.
On a system where we can call a Python module directly, we might choose to use the **http.server** module. After changing directories to one which contains content we would like to host, we can run a server directly from the command line.
Using Python 3 and **http.server**, we can use the following string to bind to 127.0.0.1 and launch a server on port 8080.
Just be sure that it's bound to 127.0.0.1 to prevent discovery through services such as [Shodan](https://www.shodan.io/).

```console
$ python3 -m http.server --bind 127.0.0.1 8080
```

In order to make testing the server easier, it may be useful to create an "index.html" file in the directory from which the server is being run. Something as simple as the file below will work.

```
<html>
<body>
W.L
</body>
</html>
```

To ensure that our server is functional, we'll want to test our local address 127.0.0.1 or `localhost` in a web browser by opening it as an address followed by a port number, as seen below:

[http://localhost:8080]([http://localhost:8080])

With our local server environment configured and available at 127.0.0.1:8080, we can now start to link our server to the Tor network.

## Section 2 - Configuring the tor service

First, you confirm that the Tor service is installed. The Tor service is separate from the Tor Browser and for Linux, it is [available here](https://2019.www.torproject.org/docs/tor-doc-unix.html.en). On Ubuntu or Debian-based distros with **apt** package manager, the following command should work assuming Tor is in the distro's repositories.

```console
$ sudo apt-get install tor
```

To confirm the location of our Tor installation and configuration, we can use **whereis**.

```console
$ whereis tor
```

This will show us a few of the directories which Tor uses for configuration. We're looking for our "torrc" file, which is most likely in /etc/tor.
In order to direct Tor to our service, we'll want to un-comment the following two lines in the `torcc` file.
To do this, we simply remove the "#" symbols at the beginning of those two lines.

```console
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:80
```

Next, we'll want to correct the port on which Tor looks for our server. If we're using port 8080, we'll want to correct the line from port 80 to port 8080. We will change the original seen below to the correct port number.
We will change this to port 8080

```console
HiddenServicePort 80 127.0.0.1:8080
```

Save and exit. If there's any permission problems just run it with `sudo`.

## Section 3 - Testing

Once we confirm that the necessary changes have been made to the `torcc` file and the python's http server is running at localhost:8080, we can simply run the following command to start the tor service.

```console
$ sudo tor
```

Upon starting Tor for the first time with our new configuration, an .onion address will be generated automatically. This information will be stored in `/var/lib/tor/hidden_service`
We then cd to that directory

```console
$ cd /var/lib/tor/hidden_service
```

After running `ls` to ensure that both the `hostname` and `private_key` files are in the directory, we can view our newly generated address.

```console
$ cat hostname
```

The string ending in .onion is our the service address.
While this one was automatically generated, we can customize it if necessary.
We can test that our service is accessible by opening it in Tor Browser.
If the address resolves to your server, you've successfully hosted a tor server!

## Section 4 - Extra (Optional)

In order to customize our onion address, we'll need to generate a new private key to match a custom hostname. Due to the nature of Tor addresses being partially hashes, in order to create a custom address, we'll need to brute-force the address we want.
The more consecutive characters of a word or phrase we'd like to use, the longer it will take to generate.

There are a few open source tools available for this, [Eschalot](https://github.com/ReclaimYourPrivacy/eschalot) and [Scallion](https://github.com/lachesis/scallion) being some of the more popular ones.
`Scallion` uses the GPU to generate addresses, while `Eschalot` works using wordlists. That's about it.
You can deploy any time of HTTP server using this, there's no requirement to stick with python's HTTP server.
You could run run the same HTTP server using Node.Js which is actually what I would personally prefer.

```console
$ npm i -g http-server
$ http-server
```

</div>
