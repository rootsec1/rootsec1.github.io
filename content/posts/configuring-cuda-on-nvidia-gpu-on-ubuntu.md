+++ 
date = 2021-02-27T21:37:49+05:30
title = "Configuring CUDA on an NVIDIA GPU for Deep Learning"
description = "If you are planning to train deep learning models using PyTorch on an NVIDIA GPU, it is essential to properly configure CUDA on your Ubuntu machine. CUDA is a parallel computing platform and programming model developed by NVIDIA for accelerating computation on GPUs. In this deep dive tutorial, we will walk through the steps to configure CUDA on an NVIDIA GPU and set up your Ubuntu machine for running deep learning models using PyTorch."
slug = ""
authors = []
tags = ["machine-learning", "ubuntu", "python"]
categories = []
externalLink = ""
series = []
+++

If you are planning to train deep learning models using PyTorch on an NVIDIA GPU, it is essential to properly configure CUDA on your Ubuntu machine. CUDA is a parallel computing platform and programming model developed by NVIDIA for accelerating computation on GPUs. In this deep dive tutorial, we will walk through the steps to configure CUDA on an NVIDIA GPU and set up your Ubuntu machine for running deep learning models using PyTorch.

## Prerequisites

Before getting started, make sure you have the following prerequisites:

- Ubuntu machine with an NVIDIA GPU.
- NVIDIA drivers installed on your machine. Ensure that the drivers are compatible with the CUDA version you plan to install.
- CUDA-compatible GPU. Check the CUDA documentation for the list of supported GPUs.

## Step 1: Install CUDA Toolkit

The first step is to install the CUDA Toolkit, which includes the necessary libraries and tools for running CUDA applications. Follow these steps to install CUDA on your Ubuntu machine:

- Visit the NVIDIA CUDA Toolkit download page: [link](https://developer.nvidia.com/cuda-downloads)
- Select your operating system, architecture, and distribution. Download the CUDA Toolkit installer for Ubuntu.
- Once the download is complete, open a terminal and navigate to the directory containing the CUDA Toolkit installer.
- Make the installer executable by running the following command:

```shell
chmod +x cuda_*.run
```

- Run the installer with administrative privileges:

```shell
sudo ./cuda_*.run
```

- Follow the on-screen prompts to install CUDA Toolkit. Choose the desired installation options based on your requirements.

- After the installation completes, add CUDA to your system's environment variables by appending the following lines to the `~/.bashrc` file:

```shell
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

- Save the file and run the following command to apply the changes:

```shell
source ~/.bashrc
```

- Verify the CUDA installation by running the following command:

```shell
nvcc --version
```

This command should display the CUDA version information if the installation was successful.

## Step 2: Configure PyTorch with CUDA support

Now that CUDA is installed on your Ubuntu machine, you need to configure PyTorch to utilize the CUDA capabilities of your GPU. PyTorch is a popular deep learning framework that provides seamless integration with CUDA for efficient GPU acceleration. Follow these steps to configure PyTorch with CUDA support:

- Install PyTorch using pip or conda. Ensure that you install the CUDA-enabled version of PyTorch that matches the CUDA Toolkit version installed on your machine. For example, if you have CUDA Toolkit 11.3 installed, use the following command to install PyTorch:

```shell
pip install torch==1.9.0+cu113 torchvision==0.10.0+cu113 torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html
```

- Once PyTorch is installed, you can check if CUDA is enabled by running the following code snippet:

```python
import torch

print(torch.cuda.is_available())
```

If the output is `True`, CUDA is successfully enabled and ready to be utilized by PyTorch.

- To utilize the GPU for training deep learning models in PyTorch, you need to move your tensors and models to the GPU device. Here's an example of how to do that:

```python
import torch

# Check if CUDA is available
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Move a tensor to the GPU
tensor = torch.tensor([1, 2, 3]).to(device)

# Move a model to the GPU
model = MyModel().to(device)
```

By utilizing the `to(device)` method, you can easily move tensors and models between the CPU and GPU.
Here's an additional code snippet to demonstrate a simple PyTorch model being trained using CUDA:

```python
import torch
import torch.nn as nn
import torch.optim as optim

# Define a simple neural network
class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.fc = nn.Linear(10, 1)

    def forward(self, x):
        x = self.fc(x)
        return x

# Create an instance of the model
model = Net()

# Move the model to the GPU if available
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# Define the input and target tensors
inputs = torch.randn(100, 10).to(device)
targets = torch.randn(100, 1).to(device)

# Define the loss function and optimizer
criterion = nn.MSELoss()
optimizer = optim.SGD(model.parameters(), lr=0.1)

# Training loop
for epoch in range(100):
    # Zero the gradients
    optimizer.zero_grad()

    # Forward pass
    outputs = model(inputs)
    loss = criterion(outputs, targets)

    # Backward pass and optimization
    loss.backward()
    optimizer.step()

    # Print the loss for each epoch
    print(f"Epoch {epoch+1}: Loss = {loss.item()}")

# Move the model back to the CPU for evaluation
model.to("cpu")
```

In this example, we define a simple neural network with a linear layer. We then move the model to the GPU using `model.to(device)` to take advantage of GPU acceleration. The input and target tensors are also moved to the GPU. We define the loss function and optimizer, and then proceed with the training loop. After training, we move the model back to the CPU for evaluation.

By utilizing CUDA, the computations involved in training the model will be executed on the GPU, leading to significant speed improvements compared to training on the CPU. Make sure to adjust the model architecture and training parameters according to your specific use case.
