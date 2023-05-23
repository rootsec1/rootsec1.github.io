+++ 
date = 2021-03-23T21:51:21+05:30
title = "Integrating Kafka as a Message Broker with NestJS"
description = "Message brokers play a crucial role in distributed systems by enabling communication between different components and services. Apache Kafka, a popular distributed streaming platform, can be seamlessly integrated with NestJS, a powerful Node.js framework, to build scalable and event-driven applications. In this blog post, we will explore how to integrate Kafka as a message broker with NestJS using a practical example."
slug = ""
authors = []
tags = ["javascript", "kafka", "infra"]
categories = []
externalLink = ""
series = []
+++

Message brokers play a crucial role in distributed systems by enabling communication between different components and services. Apache Kafka, a popular distributed streaming platform, can be seamlessly integrated with NestJS, a powerful Node.js framework, to build scalable and event-driven applications. In this blog post, we will explore how to integrate Kafka as a message broker with NestJS using a practical example.

## Prerequisites

Before proceeding, ensure you have the following prerequisites:

- Node.js and npm installed on your local machine.
- Kafka installed and running locally. You can download Kafka from the official Apache Kafka website and follow the installation instructions for your operating system.

## Step 1: Set Up a Kafka Cluster Locally

To get started, we need to set up a local Kafka cluster. Follow these steps:

- Start ZooKeeper: Kafka relies on ZooKeeper for maintaining cluster metadata. Open a terminal and run the following command to start ZooKeeper:

```shell
bin/zookeeper-server-start.sh config/zookeeper.properties
```

- Start Kafka brokers: Open a new terminal window and run the following command to start a Kafka broker:

```shell
bin/kafka-server-start.sh config/server.properties
```

You can start multiple brokers if you want to simulate a multi-node Kafka cluster.

- Create a Kafka topic: Open another terminal window and run the following command to create a Kafka topic named `test-topic`:

```shell
bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

This will create a topic with one partition and a replication factor of 1.

Now that our local Kafka cluster is set up, we can move on to integrating Kafka with NestJS.

## Step 2: Install Dependencies

To integrate Kafka with NestJS, we need to install the `kafkajs` package, which is a modern Apache Kafka client for Node.js. Open a terminal window and navigate to your NestJS project directory. Run the following command to install the required dependencies:

```shell
npm install kafka-node
```

## Step 3: Configure Kafka Producer and Consumer

In this example, we will create a simple Kafka producer and consumer using NestJS.
Create a `kafka.producer.ts` file and add the following code:

```ts
import { Kafka } from "kafkajs";

const kafka = new Kafka({
  clientId: "my-app",
  brokers: ["localhost:9092"],
});

const producer = kafka.producer();

export async function connectProducer(): Promise<void> {
  await producer.connect();
}

export async function produceMessage(
  message: string,
  topic: string
): Promise<void> {
  await producer.send({
    topic,
    messages: [{ value: message }],
  });
}
```

In this code snippet, we create a Kafka producer instance using the `kafkajs` package. We provide the broker address and a client ID. The `connectProducer` function establishes a connection to the Kafka broker, and the `produceMessage` function sends a message to the specified topic.

Create a `kafka.consumer.ts` file and add the following code:

```ts
import { Kafka } from "kafkajs";

const kafka = new Kafka({
  clientId: "my-app",
  brokers: ["localhost:9092"],
});

const consumer = kafka.consumer({ groupId: "my-group" });

export async function connectConsumer(): Promise<void> {
  await consumer.connect();
}

export async function consumeMessages(topic: string): Promise<void> {
  await consumer.subscribe({ topic });
  await consumer.run({
    eachMessage: async ({ message }) => {
      console.log(`Received message: ${message.value}`);
    },
  });
}
```

In this code snippet, we create a Kafka consumer instance using the `kafkajs` package. We provide the broker address, a client ID, and a consumer group ID. The `connectConsumer` function establishes a connection to the Kafka broker, and the `consumeMessages` function subscribes to the specified topic and logs the received messages.

## Step 4: Use Kafka in NestJS

Now that we have our Kafka producer and consumer configured, we can integrate them into our NestJS application.
In your desired NestJS module, import the `connectProducer` and `produceMessage` functions from the `kafka.producer.ts` file. Update the module to use the producer:

```ts
import { Module, OnModuleInit } from "@nestjs/common";
import { connectProducer, produceMessage } from "./kafka.producer";

@Module({
  imports: [],
  controllers: [],
  providers: [],
})
export class AppModule implements OnModuleInit {
  async onModuleInit(): Promise<void> {
    await connectProducer();
    await produceMessage("Hello, Kafka!", "test-topic");
  }
}
```

In this code snippet, we import the necessary functions from the Kafka producer file. The `onModuleInit` method is executed when the module is initialized. Inside this method, we establish a connection to the Kafka broker and send a test message to the `test-topic` topic.

In your desired NestJS module, import the `connectConsumer` and `consumeMessages` functions from the `kafka.consumer.ts` file. Update the module to use the consumer:

```ts
import { Module, OnModuleInit } from "@nestjs/common";
import { connectConsumer, consumeMessages } from "./kafka.consumer";

@Module({
  imports: [],
  controllers: [],
  providers: [],
})
export class AppModule implements OnModuleInit {
  async onModuleInit(): Promise<void> {
    await connectConsumer();
    await consumeMessages("test-topic");
  }
}
```

In this code snippet, we import the necessary functions from the Kafka consumer file. The `onModuleInit` method is executed when the module is initialized. Inside this method, we establish a connection to the Kafka broker and start consuming messages from the `test-topic` topic.

## Conclusion

In this blog post, we explored how to integrate Kafka as a message broker with NestJS. We set up a local Kafka cluster, installed the necessary dependencies, configured the Kafka producer and consumer, and integrated them into a NestJS application. This integration enables seamless communication between services using Kafka's publish-subscribe model.

Kafka's scalability, fault tolerance, and reliability make it an excellent choice for building distributed systems. By leveraging Kafka with NestJS, you can develop robust and event-driven applications that can handle large-scale message processing and real-time data streaming.
