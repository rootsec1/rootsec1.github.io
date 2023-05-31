+++ 
date = 2021-09-17T11:49:29+05:30
title = "Self-hosted Slack with video calling using open-source tech"
description = "In order to enable WebRTC functionality in Mattermost for audio and video calls, you need to set up and deploy a WebRTC server. Here, we'll explore the process of setting up a WebRTC server using Janus Gateway and integrating it with your Mattermost installation."
slug = ""
authors = []
tags = ["infra", "WebRTC", "mattermost"]
categories = []
externalLink = ""
series = []
+++

Mattermost is an open-source team collaboration platform that can be self-hosted to enhance communication and collaboration within teams. In this blog post, we will guide you through the process of setting up a Mattermost server on an AWS EC2 instance. We'll cover the steps from launching an EC2 instance to customizing the Mattermost configuration.

[customized mattermost backend repo](https://github.com/rootsec1/mbin)

[customized mattermost android app repo](https://github.com/rootsec1/mattermost-mobile)

## Setting up and Deploying a WebRTC Server for Mattermost

In order to enable WebRTC functionality in Mattermost for audio and video calls, you need to set up and deploy a WebRTC server. Here, we'll explore the process of setting up a WebRTC server using Janus Gateway and integrating it with your Mattermost installation.

#### Step 1: Installing and Configuring Janus Gateway

- Install Janus Gateway by following the official documentation: [Janus Gateway Installation](https://github.com/meetecho/janus-gateway)
- Configure Janus Gateway to use the desired ports and enable necessary modules such as the Audio Bridge and Video Call.
- Generate SSL certificates for secure communication. You can use tools like Let's Encrypt to obtain SSL certificates.

#### Step 2: Configuring Mattermost to Use the WebRTC Server

- Open the Mattermost configuration file for customization.

```shell
sudo vi /opt/mattermost/config/config.json
```

- Modify the `WebrtcSettings` section to specify the WebRTC server address and ports.

```json
"WebrtcSettings": {
    ...
    "GatewayWebRTC": "your-webrtc-server-address:your-webrtc-server-port",
    "GatewayAdminWebRTC": "your-webrtc-server-address:your-webrtc-server-admin-port",
    ...
},
```

#### Step 3: Deploying the WebRTC Server

- Copy the SSL certificates generated in Step 1 to the appropriate location on the WebRTC server.
- Start the Janus Gateway server.

```shell
janus -F your-janus-config-file.cfg
```

- Configure firewall rules to allow incoming connections on the specified ports.

If you've reached this point, you've successfully set up and deployed a WebRTC server for Mattermost. Now, Mattermost will use the WebRTC server for audio and video calls.

#### Step 4: Launching an EC2 Instance

- Login to your AWS Management Console.
- Navigate to EC2 service.
- Click on "Launch Instance" and select an appropriate Amazon Machine Image (AMI) with Linux.
- Choose an instance type and configure the instance details.
- Configure security groups to allow inbound traffic for HTTP (port 80) and HTTPS (port 443) from any source or as per your requirements.
- Review the instance details and launch the instance.

#### Step 5: Connecting to the EC2 Instance

- Once the instance is launched, obtain the public IP or DNS of the instance.
- Open a terminal or SSH client and connect to the EC2 instance using SSH.

```shell
ssh -i <your_key_pair.pem> ec2-user@<public_ip_or_dns>
```

#### Step 6: Installing and Configuring Mattermost

- Update the package manager and install the required dependencies.

```shell
sudo yum update -y
sudo yum install -y wget
```

- Download the latest stable version of Mattermost using wget.

```shell
wget https://releases.mattermost.com/<version>/mattermost-<version>-linux-amd64.tar.gz
```

- Extract the downloaded archive.

```shell
tar -xvzf mattermost-<version>-linux-amd64.tar.gz
```

- Move the extracted directory to the appropriate location.

```shell
sudo mv mattermost /opt
```

- Create a system user for Mattermost.

```shell
sudo useradd --system --user-group mattermost
sudo chown -R mattermost:mattermost /opt/mattermost
```

- Configure the Mattermost server by editing the configuration file.

```shell
sudo vi /opt/mattermost/config/config.json
```

- Customize the `TeamSettings` section to configure data types for your team.

```json
"TeamSettings": {
    ...
    "EnableOpenServer": true,
    "EnableUserCreation": true,
    "EnableCustomUserStatuses": true,
    "EnableCustomEmoji": true,
    "EnableExternalFileStorage": true,
    ...
},
```

- Enable Calls over WebRTC by modifying the `WebrtcSettings` section.

```json
"WebrtcSettings": {
    ...
    "Enable": true,
    "GatewayWebRTC": "media.example.com:443",
    "GatewayAdminWebRTC": "media.example.com:443",
    ...
},
```

Customize the necessary settings such as server URL, database connection, and email configuration.

## Step 7: Starting the Mattermost Server

- Change the ownership of the Mattermost data directory.

```shell
sudo chown -R mattermost:mattermost /opt/mattermost/data
```

- Start the Mattermost server.

```shell
sudo systemctl enable mattermost
sudo systemctl start mattermost
```

## Step 8: Accessing Mattermost

- Open a web browser and enter the URL or IP address of your Mattermost server.
- Follow the initial setup wizard to create an admin account and configure your team.
- Once the setup is complete, you can invite team members and start collaborating on Mattermost.
- To enable calls over WebRTC, configure your network to forward ports 443 and 80 to the Mattermost server.
- Open a web browser and enter the URL or IP address of your Mattermost server.

You have successfully set up a Mattermost server on an AWS EC2 instance. You can now customize the Mattermost server further by configuring data types and enabling calls over WebRTC. Remember to configure SSL/TLS encryption and enable firewall rules for secure communication. Additionally, consider following best practices for server administration to ensure the reliability and security of your Mattermost server.
