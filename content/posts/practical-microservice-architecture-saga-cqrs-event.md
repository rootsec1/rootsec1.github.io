+++ 
date = 2021-04-23T22:03:42+05:30
title = "Practical microservice arch: Saga, CQRS and Event pattern"
description = "Microservice architecture has gained significant popularity in building scalable and maintainable systems. It allows breaking down a complex application into smaller, independent services that can be developed, deployed, and scaled independently. In this blog post, we will explore three important concepts of microservice architecture: Saga, CQRS, and Event Pattern."
slug = ""
authors = []
tags = ["infra", "javascript", "microservices"]
categories = []
externalLink = ""
series = []
+++

Microservice architecture has gained significant popularity in building scalable and maintainable systems. It allows breaking down a complex application into smaller, independent services that can be developed, deployed, and scaled independently. In this blog post, we will explore three important concepts of microservice architecture: Saga, CQRS, and Event Pattern.

## Understanding Microservice Architecture

Microservice architecture is an architectural style where an application is composed of loosely coupled services that communicate with each other through APIs. Each service is responsible for a specific business capability and can be developed and deployed independently. This approach enables better scalability, fault isolation, and flexibility in building complex systems.

## Saga Pattern

The Saga pattern is a technique to manage long-running transactions across multiple microservices. In a distributed system, a business transaction might involve multiple services, and ensuring the consistency of data across services can be challenging. The Saga pattern provides a way to handle these distributed transactions by breaking them down into a series of smaller, independent steps called saga steps.

Each saga step represents an operation performed by a specific service. If a step fails, compensating actions can be executed to undo the changes made by previous steps. This ensures that the system can recover from failures and maintain consistency.

Here's an example of a simple saga implemented using Node.js and Express:

```js
// Step 1: Create Order
app.post("/orders", async (req, res) => {
  try {
    const { orderId, customerId, amount } = req.body;

    // Perform necessary actions to create the order

    // Publish event to indicate order creation
    eventBus.publish("orderCreated", { orderId, customerId, amount });

    res.status(201).json({ message: "Order created successfully" });
  } catch (error) {
    // Handle error and compensate for any previous steps if necessary
    res.status(500).json({ error: "Failed to create order" });
  }
});

// Step 2: Process Payment
app.post("/payments", async (req, res) => {
  try {
    const { orderId, customerId, amount } = req.body;

    // Perform necessary actions to process the payment

    // Publish event to indicate payment processed
    eventBus.publish("paymentProcessed", { orderId, customerId, amount });

    res.status(200).json({ message: "Payment processed successfully" });
  } catch (error) {
    // Handle error and compensate for any previous steps if necessary
    res.status(500).json({ error: "Failed to process payment" });
  }
});

// Step 3: Send Shipping Notification
app.post("/notifications", async (req, res) => {
  try {
    const { orderId, customerId } = req.body;

    // Perform necessary actions to send the shipping notification

    // Publish event to indicate shipping notification sent
    eventBus.publish("shippingNotificationSent", { orderId, customerId });

    res
      .status(200)
      .json({ message: "Shipping notification sent successfully" });
  } catch (error) {
    // Handle error and compensate for any previous steps if necessary
    res.status(500).json({ error: "Failed to send shipping notification" });
  }
});
```

In this example, we have three saga steps: creating an order, processing payment, and sending a shipping notification. If any step fails, appropriate compensating actions can be taken to revert the changes made by previous steps.

## CQRS (Command Query Responsibility Segregation)

CQRS is an architectural pattern that separates the read and write operations in an application. It distinguishes between commands that modify data and queries that retrieve data. By separating these concerns, CQRS allows optimizing the application for different read and write requirements.

InCQRS, the write operations (commands) are handled separately from the read operations (queries). This enables designing independent models for reading and writing, which can be optimized for their specific requirements.

Here's an example of implementing CQRS using Node.js and Express:

```js
// Command: Create Product
app.post("/products", async (req, res) => {
  try {
    const { name, price } = req.body;

    // Perform necessary actions to create the product

    // Publish event to indicate product created
    eventBus.publish("productCreated", { name, price });

    res.status(201).json({ message: "Product created successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to create product" });
  }
});

// Query: Get Product
app.get("/products/:productId", async (req, res) => {
  try {
    const productId = req.params.productId;

    // Perform necessary actions to retrieve the product

    res.status(200).json(product);
  } catch (error) {
    res.status(500).json({ error: "Failed to retrieve product" });
  }
});
```

In this example, the `/products` route handles the create command for creating a product, while the `/products/:productId` route handles the query for retrieving a specific product. By separating the write and read operations, we can optimize each operation independently based on its specific requirements.

## Event Pattern

The Event pattern is a key component of microservice architecture. It allows services to communicate asynchronously through events. When an event occurs, it is published to a message broker, and interested services can subscribe to these events and react accordingly.

Here's an example of using events in a Node.js application:

```js
// Event: Product Created
eventBus.subscribe("productCreated", (event) => {
  const { name, price } = event;

  // Perform necessary actions when a product is created
  console.log(`Product Created: ${name}, Price: ${price}`);
});

// Event: Order Created
eventBus.subscribe("orderCreated", (event) => {
  const { orderId, customerId, amount } = event;

  // Perform necessary actions when an order is created
  console.log(
    `Order Created: ${orderId}, Customer: ${customerId}, Amount: ${amount}`
  );
});
```

In this example, we have two event subscribers listening to the `productCreated` and `orderCreated` events. When these events are published, the corresponding event handlers are executed, allowing services to react to the events and perform necessary actions.

## Conclusion

In this blog post, we delved into three important concepts of microservice architecture: Saga, CQRS, and Event Pattern. The Saga pattern helps manage distributed transactions, CQRS separates read and write operations for optimization, and the Event pattern enables asynchronous communication between services.

By understanding and implementing these concepts, you can design and build scalable, resilient, and decoupled microservice-based systems. Each concept offers unique benefits and addresses specific challenges in distributed systems. Incorporating these patterns can enhance the performance, reliability, and maintainability of your microservice architecture.

Remember, microservice architecture is not a one-size-fits-all solution, and careful consideration should be given to the specific requirements and characteristics of your application.
