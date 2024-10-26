# Project #3 README
Project 3 focuses on implementing a Chord: P2P System and Simulation

# Note
There are two directories included. To use the Pony Crypto package (allows for using SHA256 for consistent hashing) the installation of corral and compilation of the Pony program must use Corral.
Therefore the directory "Insert Directory Name" uses the Crypto package and compiles using ``` corral run -- ponyc ```. The other directory, "Insert Other Directory Name", does not use external packages and compiles using ```ponyc```


## Group Members
Conrad Testagrose

## Dependencies
Before proceeding, please ensure proper installation of Pony by following the guidelines posted here: https://github.com/ponylang/ponyc. In order to run the code that uses SHA256 please install corral from the ponylang/corral official github: https://github.com/ponylang/corral 


## Usage
To run the compiled Pony code use:
```
DOS_Project_3 <Num_Nodes/Peers> <Num_Messages_Per_Node/Peer>
```

## Workflow
After running and providing the input, a centralized Actor will begin the simulation by spawning the nodes and assigning them ids
- In the implementation using SHA256, a "fake/simulated" IPV4 address will be assigned to each actor and then hashed to provide an id.
- In the implementation not using the SHA256 
