# Project 1 README
Project one focuses on finding perfect squares that are sums of consecutive
squares. 
* Pythagorean Identity: 3^2 + 4^2 = 5^2
* Lucas‘ Square Pyramid : 1^2 + 2^2 + ... + 24^2 = 70^2

The Pony programs developed for this project will take user input and determine if there exists any perfect squares that are sums of consecutive squares of a given sequence length and an ending search value. The programs will leverage the Actor model to build a solution that scales well on multi-core machines. 


## Dependencies
Before proceeding, please ensure proper installation of Pony by following the guidelines posted here: https://github.com/ponylang/ponyc

## This directory contains two folders that correspond to different setups for running Project 1.
## 1. Project_One_Non_Remote (The Main Deliverable)
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



## 2. Project_One_Remote (Bonus Deliverable)
This folder contains the Server and Client Pony code files designed to run Project 1 on two machines.
Two computers are necessary to run this code as intended. 

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

![image](https://github.com/user-attachments/assets/691d37d0-7061-4f0a-85e8-9d71d0511495)


We can sum the returned ```user``` and ```sys``` times and divide this value by the returned ```real``` time to obtain a ratio.

### 1. Performance Results
I determined that the size of the work unit that results in best performance can be calculated by taking the ending value and dividing that by the number of workers. Each worker will be given a range of consecutive values to caluclate the consecutive sum of squares for. If the worker finds one, they will report it and continue to the next number in their range. 

Due to the nature of how I am assigning the work to the workers, the number of sub-problems is dependent on the input ending value and the number of workers.

Obtaining the run time for ```time ./Project_One_Non_Remote 1000000 4```: (64000 Workers were used - see additional analysis below)
![image](https://github.com/user-attachments/assets/ae08c87a-2461-44c5-bf2e-36b4c49d0674)
Given the output from the time command we can calculate the CPU time to Real Time ratio
* (0.063 + 0.469) / 0.120 = 4.43
This result shows that effective parallelization is taking place.

We can also increase the problem size and perform ```time ./Project_One_Non_Remote 100000000 20```:
![image](https://github.com/user-attachments/assets/c53c6b4a-f689-4258-893f-8d73b6826fe9)
* (0.078 + 11.750) / 1.489 = 7.94

To determine how increasing the problem size and the number of workers, additional analysis was performed. 

Performance was tracked for end values up to 1,000,000,000 and a sequence length of 2 for 64, 640, 6400, and 64000 workers. This analysis was performed using the non remote program to isolate performance of the program from networking latencies. 

![image](https://github.com/user-attachments/assets/709586e9-0f28-4630-95d2-7a8d47316720)
![image](https://github.com/user-attachments/assets/47507e2d-b426-4869-a35c-5d091743fa87)

The calculated CPU time to Real Time ratio shows that as the as we increase the number of workers we see that the code is being parallelized more effectively. For very small problem sizes results seem random, implying that there is some overhead involved in parallelizing such a small problem. For large problem sizes we see that for all worker sizes we are achieving effect parallelization of the code. 

#### 2. The Pony program that runs using two computers cannot be accurately timed by running the ```time``` command in Linux terminal. Therefore, in order to time the parallelism of the remote code the "Worker" actors will keep track of their start times and the "Boss" actor will sum the time taken by each worker to determine a total time. The time will be printed on the Server side and not presented to Client.

![image](https://github.com/user-attachments/assets/35ff838a-c595-451f-9c02-ab7712b3287c)

We can divide the ```Total worker CPU time (sec)``` value by the returned ```Real elapsed time (sec)``` to obtain a ratio.

The raw ratios calculated by summing the time spent by each worker and dividing by the real time are displayed in the table below. These values were normalized for visualization purposes in the line chart below. 
![image](https://github.com/user-attachments/assets/36280f9f-e11a-4ae3-852a-e476e4f48bf3)
![image](https://github.com/user-attachments/assets/356e47cc-83ac-4508-834f-40b147656f52)

The results for the remote code show similar performance to non remote code with some interesting results for 64000 workers. The parallel ratio appears to be best for 64 workers as it increases as the problem size increases. The adjustments made to the code to make it remote may be to blame for the reduction in the parallel ratio for more workers. Due to being new to Pony, I am certain there are areas of the code that could benefit from optimization or may be causing a slight reduction in the parallel efficiency. 

#### 3. Largest Problems Solved
Below is a collection of screenshots showing some of the largest problems I was able to solve using the non remote code. 
![image](https://github.com/user-attachments/assets/83ae9ff6-6045-45bf-bc03-99aad337f56c)
![image](https://github.com/user-attachments/assets/1599f1b2-83da-4377-8771-92c5c9077151)
![image](https://github.com/user-attachments/assets/e5b9c977-e11c-4789-92f3-3a397a24ab4f)
![image](https://github.com/user-attachments/assets/4229dd78-40f9-4110-8cf4-19ed89f1155e)
![image](https://github.com/user-attachments/assets/d74d1441-eeac-4e02-a7ef-a2c7b6ffb019)

