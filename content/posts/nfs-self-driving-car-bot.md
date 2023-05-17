+++ 
date = 2020-01-18T00:13:01+05:30
title = "Building a self driving car bot for NFS Rivals"
description = "Using a convolution neural network to artificially drive a car in NFS Rivals"
slug = ""
authors = []
tags = ["self-driving", "pytorch", "machine-learning"]
categories = []
externalLink = ""
series = []
+++

# Building a Self-Driving Car Bot for the Game NFS Rivals using Deep Neural Networks

| [![self driving car bot](./self_drive_nfs_rivals_ss.png)](./self_drive_nfs_rivals.mp4) |
| :------------------------------------------------------------------------------------: |
|                       [play full video](./self_drive_nfs_rivals.mp4)                        |

Recently, I had the opportunity to work on an intriguing task: building a self-driving car bot for the popular game NFS Rivals. In this blog post, I will share my experience and insights into the technical aspects of this project.

## The Objective

The primary goal of this project was to develop an AI-driven agent capable of driving a car autonomously in the virtual world of NFS Rivals. To achieve this, I decided to leverage the power of deep neural networks, specifically using PyTorch as our deep learning framework.

## The Tech Stack

To accomplish our objective, I employed a combination of cutting-edge technologies. Our tech stack consisted of:

- **PyTorch**: I chose PyTorch due to its ease of use and excellent support for building neural networks. Its flexibility and extensive collection of pre-trained models made it a perfect fit for our project.
- **OpenCV**: To capture frames from the game in real-time, I utilized OpenCV. This powerful computer vision library enabled us to process and extract essential visual information from the game environment.
- **Direct X API**: To send commands to the game, I leveraged the Direct X API provided by Windows. This allowed us to control the car's steering, acceleration, and braking actions.

## Code Snippet

```python
import torch
import torch.nn as nn
import torch.optim as optim
import cv2
import directx

# Define the CNN architecture
class ConvNet(nn.Module):
    def __init__(self):
        super(ConvNet, self).__init__()
        self.conv1 = nn.Conv2d(3, 16, kernel_size=3, stride=1, padding=1)
        self.relu = nn.ReLU()
        self.fc1 = nn.Linear(16 * 32 * 32, 256)
        self.fc2 = nn.Linear(256, 3)  # 3 output actions: steering, acceleration, braking

    def forward(self, x):
        x = self.relu(self.conv1(x))
        x = x.view(x.size(0), -1)
        x = self.relu(self.fc1(x))
        x = self.fc2(x)
        return x

# Create an instance of the CNN
model = ConvNet()

# Define the loss function and optimizer
criterion = nn.CrossEntropyLoss()
optimizer = optim.SGD(model.parameters(), lr=0.001, momentum=0.9)

# Capture frames using OpenCV
cap = cv2.VideoCapture(0)

# Game loop
while True:
    ret, frame = cap.read()
    
    # Preprocess frame
    # ...
    
    # Convert frame to tensor
    frame_tensor = torch.from_numpy(frame).permute(2, 0, 1).unsqueeze(0).float()
    
    # Forward pass through the model
    output = model(frame_tensor)
    
    # Get predicted actions
    _, predicted_actions = torch.max(output.data, 1)
    
    # Send commands to the game using Direct X API
    # ...
    
    # Backpropagation and optimization
    # ...
```

## The Approach

Our approach involved training a deep neural network to predict the optimal actions for the car at any given moment. The network took the game frames captured by OpenCV as input and outputted the appropriate control commands. Here's a high-level overview of the steps I followed:

1. **Data Collection**: I began by capturing frames from the game using OpenCV. These frames served as the training data for our neural network. Additionally, I recorded the corresponding control commands executed by human players to create a labeled dataset for supervised learning.

2. **Data Preprocessing**: Before feeding the captured frames into the neural network, I preprocessed them by resizing, normalizing, and converting them into suitable tensor representations. This step ensured compatibility with the network architecture.

3. **Neural Network Architecture**: For our deep neural network, I designed a convolutional neural network (CNN) that could effectively learn from the visual input and predict the appropriate actions. The architecture was built using PyTorch and consisted of several convolutional layers, followed by fully connected layers.

4. **Training and Optimization**: With the architecture in place, I trained the neural network using the labeled dataset. I employed techniques such as stochastic gradient descent (SGD) and backpropagation to optimize the network's weights and biases, minimizing the prediction errors.

5. **Testing and Fine-tuning**: After training, I tested the model's performance by letting it drive the car autonomously in the game environment. Based on the bot's performance, I iteratively fine-tuned the model, adjusting hyperparameters and incorporating new data if necessary.

## Challenges and Learnings

Throughout the development process, I encountered several challenges. The first hurdle was ensuring a seamless integration between the game and our bot. I overcame this by utilizing the Direct X API to send commands to the game, allowing the bot to interact effectively.

Additionally, training a self-driving car bot requires a substantial amount of labeled data. Acquiring this data was time-consuming and required manual efforts. However, it taught us the importance of data quality and diversity in achieving better model performance.
