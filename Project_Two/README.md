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

Time to Converge for Push-Sum in milliseconds (ms)
| Number of Nodes | Line     | Full  | 3D     | Imperfect 3D |
| --------------- | -------- | ----- | ------ | ------------ |
| 10              | 239.08	  | 58.32 | 120.11 |	86.68        |
| 25              | 533.61	  | 65.47 |	185.62 |	129.18       |
| 50              | 1063.05  | 69.87 |	254.16 |	142.99       |
| 75              | 1373.25  | 75.66 |	417.81 |	169.50       |
| 100             | 2120.77  | 81.38 |	461.42 |	166.21       |
| 125             | 3211.04  | 82.03 |	504.94 |	190.28       |
| 150             | 3629.06  | 84.35 |	596.97 |	201.67       |

Largest Network Tests
Gossip
| Number of Nodes | Line     | Full    | 3D     | Imperfect 3D |
| --------------- | -------- | ------- | ------ | ------------ |
| 100             | 123.43   | 13.85   |	13.97  |	14.46       |
| 250             | 279.70   | 48.69   |	56.72  |	46.12       |
| 500             | 663.20   | 81.14   |	100.39 |	92.12       |
| 1000            | N/A      | 128.46  |	135.87 |	115.15      |
| 2500            | N/A      | 1445.83 |  N/A    |	N/A         |
| 5000            | N/A      | 5070.31 |	N/A    |	N/A         |

## Discussion
From the results for both Gossip and Push-Sum we can see that the Line topology is the slowest to converge. This result is clearly due to the 2D nature of the topology, bottlenecking the propagation of the rumor/push-sum. The next slowest to converge was the 3D grid topology, like the 2D topology, the 3D topology is restricted by the number of neighbors that the nodes have (6 in this case vs. 2 for Line). Imperfect 3D grid was the second fastest topology for convergence, this is due to each node having an additional neighbor outside of its 6 immediate neighboring nodes. The fastest topology to converge was the Full (Complete) topology. This is an expected result as each node has connections to all other nodes in the topology, allowing for quick convergence of rumors and push-sums. 

## Interesting Observations
1. Due to the random selection of the starting worker there can be outliers in the timing of convergence for both algorithms on the Line topology.
2. Using more than 5000 workers/node/actors on a moderately powerful gaming laptop (Intel i7 and 16 GB of RAM) for the Full Topology causes linux terminal to crash and force close the program - this was noticed when running experiments for the largest network size for each algorithm.

