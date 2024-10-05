# Project 2 README
Project two focuses on Gossip algorithms. Gossip algorithms can be utilized for both group communication and aggregate computational tasks. The goal of this project is to determine the convergence of both rumor propogation and push-sum algorithms using simulations in Pony. Since actors in Pony are fully asynchronous, Asynchronous Gossip is used to accomplish this task.

## Group Members
Conrad Testagrose

## Dependencies
Before proceeding, please ensure proper installation of Pony by following the guidelines posted here: https://github.com/ponylang/ponyc

## Algorithms
1. Gossip: Propogate a rumor to all actors startings from a single actor.
2. Push-Sum: Computes a sum estimate using random messages passed to actors in a given topology.

## Topologies
1. Line: Actors are arranged a 2D line with each actor (excluding the first and last) having two neighbors (the actor immediately before and after).
2. Full: Any given actor is a neighbor to all other actors in the topology (Complete Graph)
3. 3D: Actors are arranged in a 3D grid. Each actor has 6 neighbors and can only pass messages to those neighbors.
4. Imperfect3D: Actors are arranged in a 3D grid, however, each actor has an additional connection to a random actor not including itself or any of it current neighbors. 

## Work-Flow
When the program is started, the following steps occur:

1. **Read Terminal Input**
   - Main actor reads input and spawns a Coordinator actor.
3. **Coordinator Actor**
    - Spawns the requested number of workers.
    - Creates the requested topology with the spawned workers.
    - The Coordinator then tells a worker to either start propogating a rumor or start push-sum.
    - If the algorithm is push-sum each worker starts with quantities s and w (the starting values of s and w are the worker's id and 1 repectively).
4. **Worker Actors**
    - If Gossip is the algorithm: Workers will randomly select a neighbor and tell that worker the rumor. (This algorithm is considered converged when each actor has received the rumor 3 times)
    - If Push-Sum: Workers will randomly select a worker and halve its values of s and w. Half is kept and the other half if sent to the other worker. The receiving worker will then add these values to their own and repeat the process. (This algorithm is considered converged when the ratio of s and w for each actor is stable for 3 messages received)

### Usage
Navigate to the project directory and run the following command
```
ponyc
```

![image]()


After the pony code has been compiled run the program with the following command:
```
./Project_Two <Number of Workers> <Topology> <Algorithm>
```

## What is Working
I was able to implement both algorithms and all the topologies.


## Experimental Results
Time to Converge for Gossip in milliseconds (ms)
| Number of Nodes | Line     | Full  | 3D    | Imperfect 3D |
| --------------- | -------- | ----- | ----- | ------------ |
| 10              | 9.71     | 8.53  |	7.50  |	6.36        |
| 25              | 23.49    | 10.19 |	11.41 |	10.66       |
| 50              | 57.50    | 13.11 |	17.10 |	13.21       |
| 75              | 108.33   | 13.80 |	18.10 |	14.21       |
| 100             | 118.87   | 14.66 |	19.93 |	17.66       |
| 125             | 149.12   | 15.22 |	22.68 |	17.42       |
| 150             | 169.12   | 16.57 |	23.57 |	17.90       |

## Interesting Observations
1. Due to the random selection of the starting worker there can be outliers in the timing of convergence for both algorithms on the Line topology.
2. Using more than 5000 workers/node/actors on a moderately powerful gaming laptop (Intel i7 and 16 GB of RAM) for the Full Topology causes linux terminal to crash and force close the program - this was noticed when running experiments for the largest network size for each algorithm.

