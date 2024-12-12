
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

## What is Currently Working
- Client
  - [X] RESTful client that communicates to the server.
- Server
  - [X] RESTful server that communicates with the client.
- Reddit engine:
  - [X] Register account (Clients provide only usernames for simplicity right now)
  - [X] Create & join sub-reddit; leave sub-reddit (Clients can create/join/leave subreddits)
  - [X] Post in sub-reddit. (Clients can currently post simple randomized text in subreddits)
  - [X] Comment in sub-reddit. (Clients can currently comment simple randomized text on posts and comments within subreddits)
  - [X] Hierarchical comments (Users can comment on comments/posts in hierarchical format) 
  - [X] Upvote, downvote, compute Karma (Clients can upvote and downvote, karma is computed)
  - [X] Get feed of posts (Clients can get a current feed of the subreddits they subscribe to) - have other filtering methods (hot, new, etc.) but they are not implemented into the client yet
