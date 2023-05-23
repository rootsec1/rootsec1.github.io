+++ 
date = 2021-01-20T13:08:29+05:30
title = "P1 on-call alerting using NewRelic, Grafana and OpsGenie"
description = "Monitoring and alerting are crucial aspects of managing and maintaining the health of a production application. In this tutorial, we will explore how to integrate alerting and monitoring into a Python Django application using popular tools such as Sentry, New Relic, Opsgenie, Loki, and Grafana."
slug = ""
authors = []
tags = ["infra", "observability", "python"]
categories = []
externalLink = ""
series = []
+++

# Integrating Alerting and Monitoring in a Python Django Application

Monitoring and alerting are crucial aspects of managing and maintaining the health of a production application. In this tutorial, we will explore how to integrate alerting and monitoring into a Python Django application using popular tools such as Sentry, New Relic, Opsgenie, Loki, and Grafana.

## Prerequisites

Before proceeding, make sure you have the following set up:

- Python and Django installed on your development machine
- Accounts set up for Sentry, New Relic, Opsgenie, Loki, and Grafana

## Setting Up Sentry for Error Monitoring

Sentry is an error monitoring and tracking platform that helps you identify and debug issues in your application. To integrate Sentry with your Django application, follow these steps:

Install the Sentry SDK:

```shell
$ pip install sentry-sdk
```

Import and configure the Sentry SDK in your Django settings:

```python
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn="YOUR_SENTRY_DSN",
    integrations=[DjangoIntegration()],
    traces_sample_rate=1.0
)
```

Replace `YOUR_SENTRY_DSN` with your actual Sentry DSN.

Test the Sentry integration by intentionally raising an exception in your Django code. Sentry will capture the error and provide detailed information in your Sentry dashboard.

## Setting Up Opsgenie for Alerting

Opsgenie is an incident management platform that enables you to receive alerts and respond to incidents promptly. To integrate Opsgenie with your Django application, follow these steps:

- Create an Opsgenie account and obtain the API key.
- Install the Opsgenie Python SDK:

```shell
$ pip install opsgenie-sdk
```

- Import the Opsgenie SDK and configure it in your Django code:

```python
from opsgenie import OpsGenie

opsgenie = OpsGenie(api_key='YOUR_OPSGENIE_API_KEY')
```

- Use the Opsgenie SDK to send alerts when specific conditions are met in your Django code:

```python
alert_config = {
    'message': 'High CPU usage detected',
    'description': 'CPU usage is above the threshold',
    'priority': 'P1'
}
opsgenie.alert.create_alert(alert_config)
```

Customize the alert message, description, and priority based on your application's requirements.

Here's an additional code snippet to demonstrate how to handle on-call rotations for alerts using Opsgenie:

```python
from opsgenie import OpsGenie

# Configure Opsgenie SDK
opsgenie = OpsGenie(api_key='YOUR_OPSGENIE_API_KEY')

# Define the on-call schedule
on_call_schedule = {
    'name': 'On-Call Rotation',
    'rotation': [
        {'user': 'user1@example.com', 'startTime': '08:00', 'endTime': '16:00'},
        {'user': 'user2@example.com', 'startTime': '16:00', 'endTime': '00:00'},
        {'user': 'user3@example.com', 'startTime': '00:00', 'endTime': '08:00'}
    ]
}

# Create the on-call schedule
response = opsgenie.schedule.create_schedule(on_call_schedule)
schedule_id = response['data']['id']

# Create an alert with the on-call schedule
alert_config = {
    'message': 'High CPU usage detected',
    'description': 'CPU usage is above the threshold',
    'priority': 'P1',
    'onCall': [schedule_id]  # Assign the on-call schedule to the alert
}
opsgenie.alert.create_alert(alert_config)
```

In this code snippet, we define an on-call schedule with a rotation of users and their corresponding start and end times. We then create the on-call schedule using the Opsgenie SDK. Finally, when creating an alert, we assign the on-call schedule to the `onCall` field of the alert configuration. This ensures that the alert is sent to the appropriate user based on the on-call rotation schedule.

By leveraging Opsgenie's on-call schedules, you can ensure that alerts are routed to the correct team members during specific time periods, enabling effective incident response and reducing response times.

Remember to replace `YOUR_OPSGENIE_API_KEY` with your actual Opsgenie API key.

## Setting Up Opsgenie for Alerting

Opsgenie is an incident management platform that enables you to receive alerts and respond to incidents promptly. To integrate Opsgenie with your Django application, follow these steps:

- Create an Opsgenie account and obtain the API key.
- Install the Opsgenie Python SDK:

```shell
$ pip install opsgenie-sdk
```

- Import the Opsgenie SDK and configure it in your Django code:

```python
from opsgenie import OpsGenie

opsgenie = OpsGenie(api_key='YOUR_OPSGENIE_API_KEY')
```

Replace `YOUR_OPSGENIE_API_KEY` with your actual Opsgenie API key.

- Use the Opsgenie SDK to send alerts when specific conditions are met in your Django code:

```python
alert_config = {
    'message': 'High CPU usage detected',
    'description': 'CPU usage is above the threshold',
    'priority': 'P1'
}
opsgenie.alert.create_alert(alert_config)
```

Here's how to get CPU, memory, and disk space utilization for containers using New Relic and configure alerts on them to trigger a call using Opsgenie:

```python
import newrelic.agent
from opsgenie import OpsGenie

# Configure New Relic agent
newrelic.agent.initialize('/path/to/your/newrelic.ini')

# Configure Opsgenie SDK
opsgenie = OpsGenie(api_key='YOUR_OPSGENIE_API_KEY')

# Get CPU, memory, and disk space utilization using New Relic API
cpu_utilization = newrelic.agent.cpu_utilization()
memory_utilization = newrelic.agent.memory_utilization()
disk_utilization = newrelic.agent.disk_utilization()

# Set thresholds for alerts
cpu_threshold = 80
memory_threshold = 90
disk_threshold = 70

# Check if utilization exceeds thresholds
if cpu_utilization > cpu_threshold:
    alert_message = 'High CPU utilization detected'
    opsgenie.alert.create_alert({'message': alert_message})
if memory_utilization > memory_threshold:
    alert_message = 'High memory utilization detected'
    opsgenie.alert.create_alert({'message': alert_message})
if disk_utilization > disk_threshold:
    alert_message = 'High disk utilization detected'
    opsgenie.alert.create_alert({'message': alert_message})
```

In this code snippet, we configure the New Relic agent to initialize and gather CPU, memory, and disk space utilization metrics from the New Relic API. We then set thresholds for each utilization metric (e.g., CPU, memory, disk), and if any of the metrics exceed their respective thresholds, an alert is created in Opsgenie using the Opsgenie SDK.

Make sure to replace `YOUR_OPSGENIE_API_KEY` with your actual Opsgenie API key, and `/path/to/your/newrelic.ini` with the correct path to your New Relic configuration file.

By leveraging New Relic's metrics and Opsgenie's alerting capabilities, you can proactively monitor and trigger alerts based on CPU, memory, and disk utilization in your containers, ensuring prompt response and issue resolution.

## Log Aggregation with Loki and Grafana

Loki is a horizontally-scalable, highly-available log aggregation system, and Grafana is a popular visualization tool. Together, they provide powerful logging and monitoring capabilities. To set up Loki and Grafana for log aggregation, follow these steps:

- Install and configure Loki as per the official documentation.
- Install Grafana and configure it to connect to Loki as a data source.
- In your Django application, use a logging library such as `loguru` or `structlog` to send logs to Loki. Here's an example using `loguru`:

```python
from loguru import logger

logger.add('loki://localhost:3100', level='DEBUG')
```

Adjust the Loki server URL and log level as needed.

- Access Grafana and create dashboards to visualize the logs and set up alerts based on log patterns and metrics.

## Configure and trigger alerts from Grafana and route them to Opsgenie for on-call notifications:

- Configure Grafana to send alerts to Opsgenie:
  In the Grafana web interface, go to "Alerting" -> "Notification channels" and create a new channel for Opsgenie. Fill in the required information, such as API key, URL, and any other relevant configuration settings.

- Configure a Grafana alert rule:
  In Grafana, go to "Alerting" -> "Alert rules" and create a new rule. Define the conditions and thresholds for triggering the alert based on your specific metrics and requirements. Here's an example:

```json
{
  "name": "High CPU Usage",
  "conditions": [
    {
      "type": "query",
      "query": "A > 80" // CPU utilization above 80%
    }
  ],
  "notifications": [
    {
      "type": "opsgenie",
      "settings": {
        "opsgenieRegion": "us",
        "opsgenieMessage": "High CPU usage detected",
        "opsgeniePriority": "P1",
        "opsgenieTeams": ["your-team"]
      }
    }
  ]
}
```

Adjust the condition, message, priority, and team settings based on your requirements.

- Triggering an alert from Grafana:
  Once the alert rule is configured, Grafana will automatically trigger the alert when the defined condition is met. The alert will be sent to Opsgenie based on the configured notification channel.

By integrating Grafana with Opsgenie, you can easily route alerts from Grafana to Opsgenie for on-call notifications. This enables the designated on-call team to receive timely alerts and take appropriate actions.

Remember to replace `your-team` with the actual name or ID of your Opsgenie team.

In this post, explored how to integrate alerting and monitoring into a Python Django application using Sentry for error monitoring, New Relic for performance monitoring, Opsgenie for alerting, and Loki with Grafana for log aggregation and visualization. By combining these tools, you can gain deep insights into your application's health and respond to incidents promptly.

Remember to configure and fine-tune the alerting and monitoring tools based on your application's requirements and specific use cases.
