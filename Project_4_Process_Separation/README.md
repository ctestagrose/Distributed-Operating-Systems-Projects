# Project 4 (Part 1)

## Description
In this project, we are tasked with implementing a Reddit Clone and a client tester/simulator.

The current task is to build an engine that will be paired up with REST API/WebSockets to provide full functionality.

## Usage
### Compilation:
- Client: Navigate to the Client folder and run ```ponyc```
- Server: Navigate to the Server folder and run ```ponyc```
### Running the Reddit Server:
- Within the Server Folder run ```./Server <Num_Clients_To_Spawn>```
- The Server will start up and listen on localhost port 8989
- Upon binding, the server will then spawn the specified number of clients.
- Clients will then be set to run the simulation and interact using the reddit engine. 

### Running the Dedicated Client:
- Within the Client Folder run ```./Client <username>```
- The dedicated client allows for an individula to interact with the reddit engine and the simulation.
- The user can perform all tasks that the simulated clients can perform (send messages, post, create subreddits, etc.) with the additional capability of printing metrics from the simulation. 

## What is Currently Working
- Reddit-like engine:
  - [X] Register account (Clients provide only usernames for simplicity right now)
  - [X] Create & join sub-reddit; leave sub-reddit (Clients can create/join/leave subreddits)
  - [X] Post in sub-reddit. Make the posts just simple text. No need to support images or markdown. (Clients can currently post simple randomized text in subreddits)
  - [X] Comment in sub-reddit. Keep in mind that comments are hierarchical (i.e. you can comment on a comment) (Clients can currently comment simple randomized text on posts and comments within subreddts)
  - [X] Upvote+downvote + compute Karma (Clients can upvote and downvote, karma is computed, achievements are also assigned but not fully fleshed out yet.)
  - [X] Get feed of posts (Clients can get a current feed of the subreddits they subscribe to)
  - [X] Get list of direct messages; Reply to direct messages (Clients can send messages and reply to messages)
- Tester/Simulator
  - [X] Simulate as many users as you can
  - [ ] Simulate periods of live connection and disconnection for users
  - [X] Simulate a Zipf distribution on the number of sub-reddit members. For accounts with a lot of subscribers, increase the number of posts. Make some of these messages re-posts
- Other considerations:
  - [X] The client part (posting, commenting, subscribing) and the engine (distribute posts, track comments, etc) have to be in separate processes. Preferably, you use multiple independent client processes that simulate thousands of clients and a single-engine process
  - [X] You need to measure various aspects of your simulator and report performance (This is currently done with the dedicated client)


## Examples
