# Project 2 README
Project two focuses on Gossip algorithms. Gossip algorithms can be utilized for both group communication and aggregate computational tasks. The goal of this project is to determine the convergence of both rumor propogation and push-sum algorithms using simulations in Pony. Since actors in Pony are fully asynchronous, Asynchronous Gossip is used to accomplish this task.

## Dependencies
Before proceeding, please ensure proper installation of Pony by following the guidelines posted here: https://github.com/ponylang/ponyc

### Work-Flow
When the program is started, the following steps occur:

1. **Read Terminal Input**
   - Main actor reads input and spawns a Coordinator actor.
3. **Coordinator Actor**
    - Spawns the requested number of workers.
    - Creates the requested topology with the spawned workers.
    - The Coordinator then tells a worker to either start propogating a rumor or start push-sum
4. **Worker Actors**
    - If Gossip is the algorithm: Workers will randomly select a neighbor and tell that worker the rumor.
    - If Push-Sum: Workers will randomly select a worker and push 

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

