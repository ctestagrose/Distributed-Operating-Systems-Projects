# Project #3 README
Project 3 focuses on implementing a Chord: P2P System and Simulation (Chord: A Scalable Peer-to-peer Lookup Service for Internet Applicationsby Ion Stoica,  Robert  Morris,  David  Karger,  M.  Frans  Kaashoek,  Hari  Balakrishnan. https://pdos.csail.mit.edu/papers/ton:chord/paper-ton.pdfLinks to an external site.)

# Note
To use the Pony Crypto package (allows for using SHA for consistent hashing) the installation of corral and compilation of the Pony program must use Corral. To ensure appropriate submission of the porject and maintain compatibility with other systems I have provided two directorys (DOS_Project_3 and DOS_Project_3_SHA).
DOS_Project_3_SHA uses the Crypto package and compiles using ``` corral run -- ponyc ```. The other directory, DOS_Project_3, does not use external packages and compiles using ```ponyc```. 

Example (Non-SHA)
```
/DOS_Project_3 ponyc
```

Example (SHA)
```
/DOS_Project_3_SHA corral run ponyc 
```

## Group Members
Conrad Testagrose

## Dependencies
Before proceeding, please ensure proper installation of Pony by following the guidelines posted here: https://github.com/ponylang/ponyc. In order to run the code that uses SHA please install corral from the ponylang/corral official github: https://github.com/ponylang/corral 


## Usage
To run the compiled Pony code use:
```
DOS_Project_3 <Num_Nodes/Peers> <Num_Messages_Per_Node/Peer>
```

Example Input/Output
- Non-SHA
  ```
  /DOS_Project_3 ./DOS_Project_3 100 2       
  
  Starting Chord network... 
  Nodes sending messages... 
  Average number of hops: 3.375

  ```

- SHA
  ```
  /DOS_Project_3_SHA ./DOS_Project_3_SHA 100 2
  Generated address: 101.114.181:39912
  ...
  Generated address: 99.228.239:20561

  Starting Chord network... 
  Nodes sending messages... 
  Average number of hops: 3.215

  ```

## Workflow
After running and providing the input, a centralized Actor will begin the simulation by spawning the nodes and assigning them ids
- In the implementation using SHA.
  1. Entry point takes number of nodes and requests as arguments.
  2. A ring of N nodes with randomly assigned "fake/simulated" IPV4 addresses will be hashed to provide an id.
  3. Nodes are connected in a circular fashion where each node knows about its successor and predecessor.
  4. Finger tables are initialized by each node to ensure efficient routing of messages.
  5. The message sending (Lookup) process is initiated - each node sends M messages where M is a argument provided at runtime.
  6. The project outline asks for a message/second but I decided to have each actor wait a random amount of time between 1ns and 1sec before sending messages. This helps model random lookup and prevents too many messages being sent at the same time. 
  7. The finger tables are used to route requests efficiently.
  8. The numebr of hops taken for each lookup is tracked and reported to the actor that spawns the nodes and aggregates hop reporting.
  9. The average number of hops is reported to the user and the program terminates.
    
- In the implementation not using SHA
  1. Entry point takes number of nodes and requests as arguments.
  2. A ring of N nodes with randomly assigned IDs is created.
  3. Nodes are connected in a circular fashion where each node knows about its successor and predecessor.
  4. Finger tables are initialized by each node to ensure efficient routing of messages.
  5. The message sending (Lookup) process is initiated - each node sends M messages where M is a argument provided at runtime.
  6. The project outline asks for a message/second but I decided to have each actor wait a random amount of time between 1ns and 1sec before sending messages. This helps model random lookup and prevents too many messages being sent at the same time. 
  7. The finger tables are used to route requests efficiently.
  8. The numebr of hops taken for each lookup is tracked and reported to the actor that spawns the nodes and aggregates hop reporting.
  9. The average number of hops is reported to the user and the program terminates. 


## What is Working
1. Initialization of Chord Network (creation of peers with ids - determination of ids differs between the two implementations provided).
2. Each Peer/Node has a successor and predecessor.
3. Peers initialize finger tables - as per the publication on the Chord Protocol, this is integral to the achievement of speed of lookup.
4. Nodes attempt to look up a key and "hop" to other peers in the network until either the queried key is found on the node with the key or its successor/predecessor.
5. Nodes report the number of hops to the actor responsible for spawning the nodes and aggregating the number of hops.
6. Report the average number of hops to find a key in the network and exit.

## Largest Network Dealt With
I was able to successfully get a network of 10,000 actors to complete. A network of this size is possible due to the neture of Pony's actor paradigm. A network of greater than this size does take quite sometime to complete on a modestly powerful gaming/performance oriented laptop. Attempting 100,000 actors lead to a terminal crash. 
