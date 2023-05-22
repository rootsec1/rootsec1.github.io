+++ 
date = 2020-11-17T22:46:39+05:30
title = "CRUD ops on a decentralized storage cluster using IPFS"
description = "IPFS (InterPlanetary File System) is a distributed file system that enables decentralized storage and retrieval of data. In this blog post, we will explore how to build and deploy a decentralized app (DApp) using IPFS. We will cover uploading, listing, downloading, and updating files using multiple devices."
slug = ""
authors = []
tags = ["architecture", "infra", "storage", "decentralization"]
categories = []
externalLink = ""
series = []
+++

[link to backend-server codebase](https://github.com/rootsec1/decentralized_storage)

[link to android-app codebase](https://github.com/rootsec1/decentralized_storage_android)

IPFS (InterPlanetary File System) is a distributed file system that enables decentralized storage and retrieval of data. In this blog post, we will explore how to build and deploy a decentralized app (DApp) using IPFS. We will cover uploading, listing, downloading, and updating files using multiple devices. Let's dive in!

## Prerequisites

Before we begin, make sure you have the following prerequisites:

- Basic knowledge of web development (HTML, CSS, JavaScript)
- Node.js and npm (Node Package Manager) installed on your machine
- Git installed for version control

## Setting up the Project

To get started, follow these steps:

- Create a new directory for your project:

```shell
$ mkdir my-dapp
$ cd my-dapp
```

- Initialize a new Node.js project and install required dependencies:

```shell
$ npm init -y
$ npm install ipfs-http-client ipfs-deploy
```

- Create an `index.html` file and add the basic structure of your DApp:

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
  <head>
    <title>My Decentralized App</title>
  </head>
  <body>
    <h1>Welcome to my Decentralized App!</h1>
    <!-- Add your DApp content here -->
  </body>
</html>
```

## Uploading Files to IPFS

IPFS allows us to upload files and retrieve their unique content identifiers (CIDs). Let's add code to upload files to IPFS:

```js
// upload.js
const IPFS = require("ipfs-http-client");
const fs = require("fs");

async function uploadFile(filePath) {
  const ipfs = IPFS.create();
  const file = {
    path: filePath,
    content: fs.readFileSync(filePath),
  };

  try {
    const result = await ipfs.add(file);
    console.log("File uploaded successfully!");
    console.log("CID:", result.cid.toString());
    return result.cid.toString();
  } catch (error) {
    console.error("Error uploading file:", error);
    return null;
  }
}

module.exports = uploadFile;
```

In this code snippet, we use the `ipfs-http-client` library to create an IPFS client instance and upload a single file. The `uploadFile` function takes a file path as input, reads the file using `fs.readFileSync`, and uploads it to IPFS. The function returns the CID of the uploaded file.

## Listing Files on IPFS

To list the files available on IPFS, we can use the `ipfs-http-client` library. Add the following code to a new file called `list.js`:

```js
// list.js
const IPFS = require("ipfs-http-client");

async function listFiles() {
  const ipfs = IPFS.create();

  try {
    const result = await ipfs.files.ls("/");
    console.log("Files on IPFS:");
    result.forEach((file) => {
      console.log("Name:", file.name);
      console.log("CID:", file.cid.toString());
    });
  } catch (error) {
    console.error("Error listing files:", error);
  }
}

module.exports = listFiles;
```

This code snippet retrieves the list of files stored on IPFS by using the `ipfs.files.ls` method. It iterates through the files and logs their names and CIDs.

## Downloading Files from IPFS

To download files from IPFS, we can use the `ipfs-http-client` library. Add the following code to a new file called `download.js`:

```js
// download.js
const IPFS = require("ipfs-http-client");
const fs = require("fs");

async function downloadFile(cid, filePath) {
  const ipfs = IPFS.create();

  try {
    const stream = ipfs.cat(cid);
    const writableStream = fs.createWriteStream(filePath);

    stream.pipe(writableStream);
    console.log("File downloaded successfully!");
  } catch (error) {
    console.error("Error downloading file:", error);
  }
}

module.exports = downloadFile;
```

In this code snippet, we use the `ipfs.cat` method to retrieve the content of a file on IPFS based on its CID. The content is then piped into a writable stream, which is created using `fs.createWriteStream`. Running this script will download the file from IPFS and save it to the specified file path.

## Updating Files on IPFS

To update files on IPFS, we need to re-upload the modified file with a new CID. Here's an example of how you can update a file:

```js
// update.js
const IPFS = require("ipfs-http-client");
const fs = require("fs");

async function updateFile(cid, filePath) {
  const ipfs = IPFS.create();
  const file = {
    path: filePath,
    content: fs.readFileSync(filePath),
  };

  try {
    await ipfs.pin.rm(cid); // Unpin the old CID
    const result = await ipfs.add(file); // Upload the updated file
    console.log("File updated successfully!");
    console.log("New CID:", result.cid.toString());
    return result.cid.toString();
  } catch (error) {
    console.error("Error updating file:", error);
    return null;
  }
}

module.exports = updateFile;
```

In this code snippet, we first unpin the old CID using `ipfs.pin.rm`. Then, we read the updated file and upload it to IPFS using `ipfs.add`. The function returns the new CID of the updated file.
