
# Project 4 (Part 2)

## Group Members
Conrad Testagrose

## Description
This half of project 4 implements REST API/WebSockets with a simple client that allows for testing of reddit engine functionality.

## Dependencies
Before proceeding, please ensure proper installation of Pony by following the guidelines posted here: https://github.com/ponylang/ponyc.

## Usage
### Compilation:
- Client: Using terminal, navigate to the Client_REST folder and run ```ponyc```
- Server: Using terminal, navigate to the Server_REST folder and run ```ponyc```
### Running the Reddit Server:
- Within the Server Folder run ```./Server_REST <Num_Clients_To_Spawn>```
- The Server will start up and listen on localhost port 8989
- Upon binding, the server will then spawn the specified number of clients.

### Running the Dedicated Client:
- Within the Client Folder run ```./Client_REST <username>```
- The dedicated client allows for an individual to interact with the reddit engine and the simulation.
- The user can perform all tasks that the simulated clients can perform (post, create subreddits, etc.) with the additional capability of printing metrics from the simulation. 
