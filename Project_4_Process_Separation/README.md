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
  - [X] Simulate periods of live connection and disconnection for users (Users will go offline/online)
  - [X] Simulate a Zipf distribution on the number of sub-reddit members. For accounts with a lot of subscribers, increase the number of posts. Make some of these messages re-posts
- Other considerations:
  - [X] The client part (posting, commenting, subscribing) and the engine (distribute posts, track comments, etc) have to be in separate processes. Preferably, you use multiple independent client processes that simulate thousands of clients and a single-engine process
  - [X] You need to measure various aspects of your simulator and report performance (This is currently done with the dedicated client)

## Running Tests
- Simulations were left to run for 10 minutes and resulting metrics were recorded. 
### 100 Initial Users (Baseline)
```
=== Reddit System Metrics ===
Posts created: 327
Comments made: 973
Total votes: 3441
Content reposts: 214
Direct messages: 456
Simulated users online: 82
Simulated users offline: 86

Hourly Rates:
-------------
Posts/hour: 1962
Comments/hour: 5838
Votes/hour: 20646
```
- 68 new users created accounts over 10 minutes
- 51% of users were offline after 10 minutes

### 1,000 Initial Users (Increase of 10x over baseline)
```
=== Reddit System Metrics ===
Posts created: 3318
Comments made: 9807
Total votes: 34460
Content reposts: 1893
Direct messages: 4847
Simulated users online: 496
Simulated users offline: 557

Hourly Rates:
-------------
Posts/hour: 19809
Comments/hour: 58549.3
Votes/hour: 205731
```
- 53 new users created accounts over 10 minutes
- 53% of users were offline after 10 minutes
- All tracked metrics saw roughly a 10x increase due to the increased number of users

### 10,000 Initial Users (Increase of 100x over baseline)

### 100,000 Initial Users (Increase of 1,000x over baseline)

### 1,000,000 Initial Users (Increase of 10,000x over baseline)
- Using this many users crashed terminal due to memory usage

## How to Use/Example Usage
### SERVER SETUP
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
### INTERACTING WITH SIMULATION VIA PROVIDED CLIENT
1. Login to Reddit:
  ```
  ./Client conrad
  Connected to Reddit server
  Sent login request for user: conrad
  Successfully logged in!
  
  === Reddit Menu ===
  1. Create Subreddit
  2. Create Post
  3. List All Posts
  4. Add Comment
  5. View Comments
  6. List All Subreddits
  7. List My Subreddits
  8. View My Feed
  9. Join Subreddit
  10. Leave Subreddit
  11. View Messages
  12. Send Message
  13. Reply to Message
  14. View My Profile
  15. View Metrics
  16. Vote on Post
  17. Vote on Comment
  18. Exit

  
  Enter your choice:
  ```
- Server acknowledges login:
  ```
  Server received: LOGIN conrad
  Login attempt from: conrad
  Login successful for: conrad
  ```
2. Before making a post or commenting, Join a subreddit:
  ```
  === Reddit Menu ===
  1. Create Subreddit
  2. Create Post
  3. List All Posts
  4. Add Comment
  5. View Comments
  6. List All Subreddits
  7. List My Subreddits
  8. View My Feed
  9. Join Subreddit
  10. Leave Subreddit
  11. View Messages
  12. Send Message
  13. Reply to Message
  14. View My Profile
  15. View Metrics
  16. Vote on Post
  17. Vote on Comment
  18. Exit

  
  Enter your choice:
  9
  Enter subreddit name to join:
  cats
  Successfully joined subreddit: cats
  ```
- Server acknowledges joining subreddit cats
  ```
  Server received: JOIN_SUBREDDIT cats
  ```
3. Create a post in a subreddit:
  ```
  === Reddit Menu ===
  1. Create Subreddit
  2. Create Post
  3. List All Posts
  4. Add Comment
  5. View Comments
  6. List All Subreddits
  7. List My Subreddits
  8. View My Feed
  9. Join Subreddit
  10. Leave Subreddit
  11. View Messages
  12. Send Message
  13. Reply to Message
  14. View My Profile
  15. View Metrics
  16. Vote on Post
  17. Vote on Comment
  18. Exit

  
  Enter your choice:
  2
  Enter subreddit name:
  cats
  Enter post title:
  I love cats
  Enter post content:
  I really love cats
  Post created successfully!
  ```
  - Server acknowledges that user has has created a post in cats 
  ```
  Server received: POST cats I_love_cats I_really_love_cats
  conrad created a post in cats: I love cats
  Post created by: conrad
  ```
4. You can list both the subreddits that you have joined and all the available subreddits:
  ```
  === Reddit Menu ===
  1. Create Subreddit
  2. Create Post
  3. List All Posts
  4. Add Comment
  5. View Comments
  6. List All Subreddits
  7. List My Subreddits
  8. View My Feed
  9. Join Subreddit
  10. Leave Subreddit
  11. View Messages
  12. Send Message
  13. Reply to Message
  14. View My Profile
  15. View Metrics
  16. Vote on Post
  17. Vote on Comment
  18. Exit

  
  Enter your choice:
  7
  
  === Available Subreddits ===
  1. cats
  
  === Reddit Menu ===
  1. Create Subreddit
  2. Create Post
  3. List All Posts
  4. Add Comment
  5. View Comments
  6. List All Subreddits
  7. List My Subreddits
  8. View My Feed
  9. Join Subreddit
  10. Leave Subreddit
  11. View Messages
  12. Send Message
  13. Reply to Message
  14. View My Profile
  15. View Metrics
  16. Vote on Post
  17. Vote on Comment
  18. Exit

  
  Enter your choice:
  6
  
  === Available Subreddits ===
  1. jokes
  2. Subreddit_1732633012
  3. Subreddit_1732633023
  4. Subreddit_1732632964
  5. gaming
  6. Subreddit_1732632941
  7. Subreddit_1732632945
  8. Subreddit_1732633007
  9. news
  10. history
  11. Subreddit_1732632970
  12. Subreddit_1732632900
  13. Subreddit_1732632934
  14. Subreddit_1732632963
  15. music
  16. funny
  17. Subreddit_1732632974
  18. technology
  19. programming
  20. movies
  21. science
  22. sports
  23. Subreddit_1732632907
  24. cats
  25. politics
  26. cars
  27. memes
  28. Subreddit_1732632980
  29. stocks
  30. pics
  31. Subreddit_1732632962
  32. Subreddit_1732633025
  33. Subreddit_1732633000
  34. Subreddit_1732632906
  35. Subreddit_1732632928
  36. Subreddit_1732632996
  37. math
  38. books
  39. Subreddit_1732633011
  ```
5. You can view your feed
  ```
  Enter your choice: 8
  === Posts ===
  Post #0
  Title: Post about cats 1732640955
  Author: gbBQyXJq9gi0aWeD
  Content: Sharing thoughts about cats
  ---

  Post #1
  Title: Post about cats 1732640960
  Author: hYWsFa3MsFyE0Zjm
  Content: Sharing thoughts about cats
  ---
  
  Post #2
  Title: [Repost] [Repost] Post about stocks 1732640884
  Author: jPUWGmeK5y2rCylY
  Content: Sharing thoughts about stocks
  
  Original by u/l6edU7pyv28HhK2Q in r/stocks
  
  Original by u/HL6iVi6ZWEliY7Ot in r/science
  ---
  
  Post #3
  Title: I love cats
  Author: conrad
  Content: I really love cats
  ---
  ```
6. You can view your profile
  ```
  Enter your choice: 14

  === User Profile ===
  Username: conrad
  Bio: 
  Join Date: 1732640873
  Post Karma: 1
  Comment Karma: 0
  Total Karma: 1
  Subreddit Karma: cats:1
  ```
7. You can also view simulation/reddit metrics
  ```
  Enter your choice: 15

  === Reddit System Metrics ===
  Posts created: 71
  Comments made: 25
  Total votes: 23
  Content reposts: 21
  Direct messages: 16
  Simulated users online: 86
  Simulated users offline: 73
  
  Hourly Rates:
  -------------
  Posts/hour: 478.652
  Comments/hour: 168.539
  Votes/hour: 155.056
  ```
