+++ 
date = 2020-11-25T22:57:54+05:30
title = "Out of the box tracing and observability using SigNoz"
description = "Signoz is an open-source observability platform that provides monitoring, alerting, and distributed tracing capabilities. In this tutorial, we will walk through the process of setting up and integrating Signoz with a Node.js app to achieve out-of-the-box alerting and monitoring."
slug = ""
authors = []
tags = ["tracing", "observability", "infra"]
categories = []
externalLink = ""
series = []
+++

Signoz is an open-source observability platform that provides monitoring, alerting, and distributed tracing capabilities. In this tutorial, we will walk through the process of setting up and integrating Signoz with a Node.js app to achieve out-of-the-box alerting and monitoring. Let's get started!

## Prerequisites

Before you begin, ensure that you have the following prerequisites:

- Basic knowledge of Node.js and npm (Node Package Manager)
- An existing Node.js application that you want to monitor and receive alerts for
- Signoz installed and running on your server or cloud infrastructure

## Install the Signoz Node.js Library

First, let's install the Signoz Node.js library into your Node.js application. Open your terminal and navigate to your project's directory. Then, run the following command:

```shell
$ npm install signoz-node-agent
```

This command will install the Signoz Node.js library, which enables automatic tracing and metrics collection for your application.

## Initialize the Signoz Agent

Next, you need to initialize the Signoz agent in your Node.js application. Open your main application file and add the following code snippet:

```js
const signoz = require("signoz-node-agent")({
  serviceName: "your-service-name",
  serviceURL: "http://your-signoz-instance:8080",
  logLevel: "info",
});

signoz.instrumentations.instrumentAll(); // Enable automatic instrumentation
```

In this code snippet, we import the Signoz library and initialize it with the configuration parameters. Replace `your-service-name` with the name of your application, and [http://your-signoz-instance:8080](http://your-signoz-instance:8080) with the URL of your Signoz instance.

The `signoz.instrumentations.instrumentAll()` line enables automatic instrumentation, which automatically traces HTTP requests, database queries, and other important components of your application.

## Add Custom Traces

To add custom traces to your code, you can use the `signoz.tracer` object provided by the Signoz agent. Here's an example of adding a trace to a specific function:

```js
function myFunction() {
  const span = signoz.tracer.startSpan("myFunction");
  // Perform some operations...
  span.finish();
}
```

In this example, we create a new span using `signoz.tracer.startSpan('myFunction')` and perform some operations within the function. Finally, we call `span.finish()` to mark the end of the span. You can add custom traces to important parts of your application to gain more visibility and insights into its behavior.

## Receive Alerts and Monitor with Signoz

Signoz provides a web-based dashboard where you can monitor the performance and health of your application. It also supports alerting based on predefined metrics and thresholds. To configure alerts, log in to your Signoz dashboard and navigate to the Alerts section. Create new alert rules based on the metrics you want to monitor, such as response time, error rate, or throughput.

## Track Custom Metrics

In addition to tracing requests and spans, Signoz allows you to track custom metrics specific to your application. Here's an example of how you can track a custom metric:

```js
signoz.metrics.track("custom_metric", 42);
```

In this code snippet, we use the `signoz.metrics.track` method to track a custom metric named `custom_metric` with a value of `42`. You can track various metrics such as response time, error rates, or any other custom metric that is relevant to your application.

## Error Logging

Signoz integrates with popular logging libraries such as Winston and Bunyan to capture and correlate error logs with traces. Here's an example of how you can configure error logging using Winston:

```js
const winston = require("winston");

// Create a Winston logger instance
const logger = winston.createLogger({
  transports: [
    new winston.transports.Console(),
    new signoz.integrations.winston.WinstonTransport(),
  ],
});

// Use the logger to log errors
logger.error("An error occurred");
```

In this code snippet, we configure a Winston logger and add the Signoz Winston transport to capture error logs. By logging errors using this configured logger, you ensure that the error logs are correlated with the traces and can be easily visualized in the Signoz dashboard.

## Instrumenting HTTP Clients

Signoz provides instrumentation for popular HTTP client libraries, such as Axios and Node-fetch. Here's an example of how you can instrument an Axios HTTP client:

```js
const axios = require("axios");

// Instrument the Axios client
const instrumentedAxios = signoz.instrumentations.http.client(axios);

// Make an HTTP request
instrumentedAxios.get("https://api.example.com/data");
```

In this code snippet, we use the `signoz.instrumentations.http.client` method to instrument the Axios client. This enables tracing of all outgoing HTTP requests made by the client. You can similarly instrument other HTTP client libraries to capture and visualize the HTTP request traces in the Signoz dashboard.

## Distributed Tracing

Signoz supports distributed tracing, which allows you to trace requests across multiple services or components of your application. To enable distributed tracing, you need to propagate trace context between services. Here's an example of how you can propagate trace context using HTTP headers:

```js
// Extract trace context from incoming HTTP headers
const traceContext = signoz.extractTraceContext(req.headers);

// Create a new HTTP client request and inject trace context
const clientRequest = http.request(
  {
    hostname: "api.example.com",
    port: 80,
    path: "/data",
    method: "GET",
    headers: signoz.injectTraceContext(traceContext),
  },
  (response) => {
    // Handle the response
  }
);

// Send the client request
clientRequest.end();
```

In this code snippet, we extract the trace context from the incoming HTTP headers using `signoz.extractTraceContext`. Then, we inject the trace context into the outgoing HTTP request headers using `signoz.injectTraceContext`. This ensures that the trace context is propagated between services, enabling end-to-end tracing.

By incorporating these additional code snippets, you can further enhance observability in your Node.js application using Signoz. You can track custom metrics, capture and correlate error logs, instrument HTTP clients, and enable distributed tracing to gain comprehensive visibility into your application's behavior. Signoz provides powerful observability features that help you identify and resolve issues, optimize performance, and ensure the reliability of your application.
