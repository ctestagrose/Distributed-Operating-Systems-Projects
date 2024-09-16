# Project 1 README
Project one focuses on finding perfect squares that are sums of consecutive
squares. 
* Pythagorean Identity: 3^2 + 4^2 = 5^2
* Lucas‘ Square Pyramid : 1^2 + 2^2 + ... + 24^2 = 70^2

The Pony programs developed for this project will take user input and determine if there exists any perfect squares that are sums of consecutive squares of a given sequence length and an ending search value. The programs will leverage the Actor model to build a solution that scales well on multi-core machines. 


## Dependencies
Before proceeding, please ensure proper installation of Pony by following the guidelines posted here: https://github.com/ponylang/ponyc

## This directory contains two folders that correspond to different setups for running Project 1.
## 1. Project_One_Non_Remote
This folder contains the Pony code necessary to run Project 1 on a single machine without a remote server.
#### Usage
Navigate to the project directory and run the following command
```
ponyc
```

![image](https://github.com/user-attachments/assets/36d82da4-7aec-4e52-9ef8-006c98d00342)

After the pony code has been compiled run the program with the following command:
```
./Project_One_Non_Remote <Ending Value> <Sequence Length>
```

![image](https://github.com/user-attachments/assets/7d3738bf-c74e-4cd5-a944-f8742fcdf870)


## 2. Project_One_Remote
This folder contains the Server and Client Pony code files designed to run Project 1 on two machines.

EXAMPLE IMAGES FOR SERVER ARE FROM WINDOWS DESKTOP MACHINE RUNNING SERVER CODE AND IMAGES FOR CLIENT ARE FROM A WINDOWS LAPTOP RUNNING CLIENT CODE IN WSL
#### Usage
On the server machine navigate to the Server subdirectory in Project_One_Remote and run the following command
```
ponyc
```

![image](https://github.com/user-attachments/assets/5ae1f52e-6360-49b9-99ff-9d96a319ecfd)

After compliation run the Server by running:
```
./Server
```

![image](https://github.com/user-attachments/assets/890be624-d4ab-42a4-b5a0-f549d35c5728)


On the sclient machine navigate to the Client subdirectory in Project_One_Remote and run the following command
```
ponyc
```

![image](https://github.com/user-attachments/assets/28826457-f245-4e45-b0d7-58f0376c0919)

After compliation run the Client by running:
```
./Client <Ending Value> <Sequence Length>
```
For Example:
```
./Client 5 2
```

![image](https://github.com/user-attachments/assets/9badda4e-b99a-46e2-80db-7ef3cb9cae22)


# Performance Analysis
#### Parallel Ratio Formula
The parallel ratio can be calculated using the following formula:
Parallel Ratio = Total CPU time / Real (Wall Clock) Time​

Values over 1 show some degree of parallelism with the larger values having greater extents of parallelism. 

#### 1. The non remote Pony program runs on a single machine and therefore can be analyzed for parallel performance by using the ```time``` command in Linux terminal.
Example:

![image](https://github.com/user-attachments/assets/79bd3f18-ebb0-4e15-a05f-8b49a6c9abcd)

We can sum the returned ```user``` and ```sys``` times and divide this value by the returned ```real``` time to obtain a ratio.

#### 2. The Pony program that runs using two computers cannot be accurately timed by running the ```time``` command in Linux terminal. Therefore, in order to time the parallelism of the remote code the "Worker" actors will keep track of their start times and the "Boss" actor will sum the time taken by each worker to determine a total time. The time will be printed on the Server side and not presented to Client.

![image](https://github.com/user-attachments/assets/35ff838a-c595-451f-9c02-ab7712b3287c)

We can divide the ```Total worker CPU time (sec)``` value by the returned ```Real elapsed time (sec)``` to obtain a ratio.
