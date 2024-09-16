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

![image](https://github.com/user-attachments/assets/96939a11-a15e-4c58-92ee-f94f49dc9b0a)


After the pony code has been compiled run the program with the following command:
```
./Project_One_Non_Remote <Ending Value> <Sequence Length>
```

![image](https://github.com/user-attachments/assets/22870936-5b13-43ba-855a-d1e772e55e12)



## 2. Project_One_Remote
This folder contains the Server and Client Pony code files designed to run Project 1 on two machines.

EXAMPLE IMAGES FOR SERVER ARE FROM WINDOWS DESKTOP MACHINE RUNNING SERVER CODE AND IMAGES FOR CLIENT ARE FROM A WINDOWS LAPTOP RUNNING CLIENT CODE IN WSL
#### Usage
On the server machine navigate to the Server subdirectory in Project_One_Remote and run the following command
```
ponyc
```

![image](https://github.com/user-attachments/assets/c473d602-9e5b-4ff2-8820-bd5dc3f3e378)


After compliation run the Server by running:
```
./Server
```

![image](https://github.com/user-attachments/assets/fccd1a04-d155-40af-805c-093b09dbc260)


On the client machine navigate to the Client subdirectory in Project_One_Remote and run the following command
```
ponyc
```

![image](https://github.com/user-attachments/assets/142cc3af-5273-4f9d-bb01-aef3e476c279)


After compliation run the Client by running:
```
./Client <Ending Value> <Sequence Length> <Server IP>
```
For Example:
```
./Client 5 2
```

![image](https://github.com/user-attachments/assets/4bb8f9b1-9e0f-49c5-b6a8-16ab15efc221)



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
