# Project #3 README
Project 3 focuses on implementing a Chord: P2P System and Simulation

# Note
There are two directories included. To use the Pony Crypto package (allows for using SHA256 for consistent hashing) the installation of corral and compilation of the Pony program must use Corral.
Therefore the directory "Insert Directory Name" uses the Crypto package and compiles using ``` corral run -- ponyc ```. The other directory, "Insert Other Directory Name", does not use external packages and compiles using ```ponyc```

Example (Non-SHA256)
```
/DOS_Project_3 ponyc
```

Example (SHA256)
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
- In the implementation using SHA, a "fake/simulated" IPV4 address will be assigned to each actor and then hashed to provide an id.
- In the implementation not using the SHA256


## What is Working
1. Initialization of Chord Network (creation of peers with ids - determination of ids differs between the two implementations provided).
2. Each Peer/Node has a successor and predecessor.
3. Peers initialize finger tables - as per the publication on the Chord Protocol, this is integral to the achievement of speed of lookup.
4. Nodes attempt to look up a key and "hop" to other peers in the network until either the queried key is found on the node with the key or its successor/predecessor.
5. Nodes report the number of hops to the actor responsible for spawning the nodes and aggregating the number of hops.
6. Report the average number of hops to find a key in the network and exit.

## Largest Network Dealt With
I was able to successfully get a network of 10,000 actors to complete. A network of this size is possible due to the neture of Pony's actor paradigm. A network of this size does take quite sometime to complete on a modestly powerful gaming/performance oriented laptop. 
