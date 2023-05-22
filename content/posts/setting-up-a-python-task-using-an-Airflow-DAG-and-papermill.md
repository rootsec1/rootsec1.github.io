+++ 
date = 2020-10-15T22:36:31+05:30
title = "Orchestrating scheduled jobs using Airflow DAGs and Papermill"
description = "Airflow is a powerful open-source platform for orchestrating and scheduling workflows. It allows you to define, schedule, and monitor complex data pipelines. In this technical guide, we will explore how to set up an Airflow server and use it to run Python Jupyter notebooks periodically. Let's get started!"
slug = ""
authors = []
tags = ["python", "airflow", "dag", "infra"]
categories = []
externalLink = ""
series = []
+++

Airflow is a powerful open-source platform for orchestrating and scheduling workflows. It allows you to define, schedule, and monitor complex data pipelines. In this technical guide, we will explore how to set up an Airflow server and use it to run Python Jupyter notebooks periodically. Let's get started!

## Prerequisites

Before we begin, ensure you have the following prerequisites:

- Python and pip installed on your system
- Docker and Docker Compose (optional, for running Airflow in containers)
- Basic knowledge of Python, Jupyter notebooks, and Docker

## Setting up Airflow

There are multiple ways to set up an Airflow environment. In this guide, we'll use Docker Compose to create a local Airflow server. Follow these steps:

Create a new directory for your Airflow project:

```shell
$ mkdir my-airflow-project
$ cd my-airflow-project
```

Create a `docker-compose.yaml` file with the following contents:

```yaml
version: "3"
services:
  webserver:
    image: apache/airflow:2.2.0
    ports:
      - "8080:8080"
    volumes:
      - ./dags:/opt/airflow/dags
      - ./logs:/opt/airflow/logs
      - ./plugins:/opt/airflow/plugins
  scheduler:
    image: apache/airflow:2.2.0
    command: scheduler
    depends_on:
      - webserver
    volumes:
      - ./dags:/opt/airflow/dags
      - ./logs:/opt/airflow/logs
      - ./plugins:/opt/airflow/plugins
```

This configuration sets up an Airflow webserver and scheduler, mapping the local directories `./dags`, `./logs`, and `./plugins` to the respective directories inside the containers.

Start the Airflow containers:

```shell
$ docker-compose up -d
```

This command downloads the Airflow images and starts the containers in the background.
Access the Airflow web interface:
Open your browser and navigate to [http://localhost:8080](http://localhost:8080). You should see the Airflow web UI, where you can configure and manage your workflows.

## Running Python Jupyter Notebooks with Airflow

To run Python Jupyter notebooks periodically using Airflow, we'll create a simple DAG (Directed Acyclic Graph) that executes a notebook at specified intervals. Follow these steps:

- Create a new Python file `my_dag.py` in the dags directory:

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.papermill_operator import PapermillOperator

default_args = {
    'owner': 'my_name',
    'depends_on_past': False,
    'start_date': datetime(2022, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

with DAG('my_dag', default_args=default_args, schedule_interval='0 0 * * *') as dag:
    task = PapermillOperator(
        task_id='execute_notebook',
        input_nb='/path/to/my_notebook.ipynb',
        output_nb='/path/to/output_notebook.ipynb',
        parameters={'param1': 'value1', 'param2': 'value2'}
    )
```

In this example, we define a DAG with a single task that executes a Jupyter notebook using the `PapermillOperator`. Adjust the paths to your specific notebook locations and provide any necessary parameters.

- Place your Jupyter notebook file (`my_notebook.ipynb`) in a directory accessible to the Airflow containers.
- Ensure the `papermill` package is installed. You can add it to your `requirements.txt` file or install it separately:

```shell
$ pip install papermill
```

- Refresh the Airflow web interface, and you should see the `my_dag` listed. Toggle the DAG's status to "On" to enable scheduling.
- Airflow will automatically run the notebook according to the specified schedule interval.

By leveraging Airflow's powerful workflow management capabilities, you can automate and orchestrate various data processing tasks, including notebook execution.
