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


## Example Usage
1. Starting Server
```
./Server 100
Starting Reddit Engine Simulation with 100
Created subreddit: programming
Created subreddit: news
Created subreddit: funny
Created subreddit: science
Created subreddit: gaming
Created subreddit: movies
Created subreddit: music
Created subreddit: books
Created subreddit: technology
Created subreddit: sports
Created subreddit: cats
Created subreddit: pics
Created subreddit: cars
Created subreddit: memes
Created subreddit: politics
Created subreddit: history
Created subreddit: jokes
Created subreddit: math
Created subreddit: music
Created subreddit: stocks

Simulation initialization complete!
Created 100 initial users
Use the simulation timer to generate ongoing activity.

Simulation initialization complete!
Use the simulation timer to generate ongoing activity.
Listening on ::1:8989
```
- Server starts (in given example, the simulation starts with 100 users - more will spawn/join reddit over time).
- The server will start with 20 default subreddits with more added by users overtime.
2. Simulated users will start to act out simulation
  ```
  mkTAiIYkDA9fct5X created a post in sports: Post about sports 1732630004
  Simulation: mkTAiIYkDA9fct5X created a post in sports
  WIBbqgd30uk43kT1 created a post in politics: Post about politics 1732630005
  Simulation: WIBbqgd30uk43kT1 created a post in politics
  J1nw3r9dEKu9bh5K created a post in music: Post about music 1732630006
  Simulation: J1nw3r9dEKu9bh5K created a post in music
  bfz8rKVOFhubFElA created a post in memes: Post about memes 1732630009
  Simulation: bfz8rKVOFhubFElA created a post in memes
  6AzPrv8PR5KZfgS5 commented on post 0
  Simulation: 6AzPrv8PR5KZfgS5 commented on post 0 in music
  6GMg1Jaqnw5V3jpJ created a post in music: Post about music 1732630012
  Simulation: 6GMg1Jaqnw5V3jpJ created a post in music
  Simulation: MarfpuZGn7Qr3GtK created a post in history
  1X2coQxpPfT7xqHy sending message to 5FVbGlcfOmshDqNL
  Simulation: 1X2coQxpPfT7xqHy messaged 5FVbGlcfOmshDqNL about post 2
  Simulation: New user registered: User_1732630028
  Simulation: New subreddit created: Subreddit_1732630028
  Simulation: qLqZMLL1RhIOK9vv joined new subreddit Subreddit_1732630028
  Simulation: g0rPZkxZOdbad64e joined new subreddit Subreddit_1732630028
  Simulation: vbkwagVweQavNR7g joined new subreddit Subreddit_1732630028
  7f24sZCuk5yN3UIP sending message to MarfpuZGn7Qr3GtK
  Simulation: 7f24sZCuk5yN3UIP messaged MarfpuZGn7Qr3GtK about post 0
  Simulation: New subreddit created: Subreddit_1732630030
  Simulation: ziEHYR5bAYVDCrgA joined new subreddit Subreddit_1732630030
  hAjkIe1eenr2MZsx created a post in stocks: Post about stocks 1732630033
  Simulation: hAjkIe1eenr2MZsx created a post in stocks
  ```
  - The simulation can be monitors from the server terminal.
  - Exmaple usage shows users creating posts, commenting, messaging each other, creating subreddits, and joining/leaving subreddits.
3. Interacting with simulation via provided client
- Server acknowledges login:
  ```
  Server received: LOGIN conrad
  Login attempt from: conrad
  Login successful for: conrad
  ```
  
  
