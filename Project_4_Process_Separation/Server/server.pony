use "net"
use "collections"
use "../Engine"
use "time"
use "random"

class SimulationUpdate is TimerNotify
  let _server: RedditServer
  var _update_count: U64 = 0
  
  new iso create(server: RedditServer) =>
    _server = server
    
  fun ref apply(timer: Timer, count: U64): Bool =>
    _server.simulate_activity()
    _update_count = _update_count + 1    
    true 
    
  fun ref cancel(timer: Timer) =>
    None


actor RedditServer is ServerNotify
  let _env: Env
  let _auth: TCPListenAuth
  let _engine: RedditEngine
  let _connections: SetIs[TCPConnection tag]
  let _usernames: Map[String, TCPConnection tag]
  let _rand: Rand
  let _num_clients: String
  let _simulated_offline_users: Set[String]

  new create(env: Env, auth: TCPListenAuth, num_clients: String) =>
    _env = env
    _auth = auth
    _engine = RedditEngine(env)
    _connections = SetIs[TCPConnection tag]
    _usernames = Map[String, TCPConnection tag]
    _rand = Rand(Time.now()._2.u64())
    _num_clients = num_clients
    _simulated_offline_users = Set[String]
    try
      _engine.run(_num_clients.u64()?)
    end
    
    TCPListener(auth, recover ServerListener(this, env) end, "localhost", "8989")

    let timers = Timers
    let timer = Timer(SimulationUpdate(this),
      1_000_000_000,
      1_000_000_000)
    timers(consume timer)
    
  be connected(conn: TCPConnection tag) =>
    _connections.set(conn)
    _env.out.print("New client connected")

  fun _decode_text(text: String): String =>
    text.clone().>replace("_", " ")

  be display_metrics() =>
    _engine.display_metrics()
    
  be received(conn: TCPConnection tag, data: Array[U8] val) =>
    try
      let start_time = Time.now()._2.f64() / 1_000_000.0
      let message = String.from_array(data)
      _env.out.print("Server received: " + message)
      
      let parts = message.split(" ")
      let command = parts(0)?

      match command
      | "LOGIN" =>
        if parts.size() >= 2 then
          let username = parts(1)?
          _env.out.print("Login attempt from: " + username)
          _usernames(username) = conn
          _engine.register_user(username)
          conn.write("LOGIN_OK " + username)
          _env.out.print("Login successful for: " + username)
        end
      | "LIST_SUBREDDITS" =>
        try
          let username = _get_username(conn)?
          let response = build_subreddits_response()
          conn.write(response)
          _env.out.print("Sent subreddits list to: " + username)
        end
      | "POST" =>
        if parts.size() >= 4 then
          try
            let username = _get_username(conn)?
            let subreddit = parts(1)?
            let title = _decode_text(parts(2)?)
            let content = _decode_text(parts(3)?)
            _engine.create_post(username, subreddit, title, content)
            conn.write("POST_OK")
            _env.out.print("Post created by: " + username)
          end
        end
      | "LIST_POSTS" =>
        try
          let username = _get_username(conn)?
          let response = build_posts_response()
          conn.write(response)
          _env.out.print("Sent posts list to: " + username)
        end
      | "COMMENT" =>
        if parts.size() >= 4 then
          try
            let username = _get_username(conn)?
            let subreddit = parts(1)?
            let post_index = parts(2)?.usize()?
            let content = parts(3)?
            _engine.add_comment(username, subreddit, post_index, content)
            conn.write("COMMENT_OK")
            _env.out.print("Comment added by: " + username)
          end
        end
      | "VIEW_COMMENTS" =>
        if parts.size() >= 3 then
          try
            let username = _get_username(conn)?
            let subreddit = parts(1)?
            let post_index = parts(2)?.usize()?
            let response = build_comments_response(subreddit, post_index)
            conn.write(response)
            _env.out.print("Sent comments list to: " + username)
          end
        end
      | "CREATE_SUBREDDIT" =>
        if parts.size() >= 2 then
          try
            let username = _get_username(conn)?
            let subreddit_name = _decode_text(parts(1)?)
            _engine.create_subreddit(subreddit_name)
            _engine.join_subreddit(username, subreddit_name)
            conn.write("SUBREDDIT_OK " + subreddit_name)
            _env.out.print("Subreddit created and joined: " + subreddit_name + " by " + username)
          end
        end
      | "JOIN_SUBREDDIT" =>
        if parts.size() >= 2 then
          try
            let username = _get_username(conn)?
            let subreddit_name = parts(1)?
            _engine.join_subreddit(username, subreddit_name)
            conn.write("JOIN_OK " + subreddit_name)
          end
        end
      | "LEAVE_SUBREDDIT" =>
        if parts.size() >= 2 then
          try
            let username = _get_username(conn)?
            let subreddit_name = parts(1)?
            _engine.leave_subreddit(username, subreddit_name)
            conn.write("LEAVE_OK " + subreddit_name)
          end
        end
      | "VIEW_MESSAGES" =>
        try
          let username = _get_username(conn)?
          let user = _engine.users(username)?
          user.get_messages_for_client(conn)
          _env.out.print("Requesting messages for: " + username)
        end
      | "LIST_JOINED_SUBREDDITS" =>
        try
          let username = _get_username(conn)?
          let response = build_joined_subreddits_response(username)
          conn.write(response)
        end

      | "LIST_FEED" =>
        try
          let username = _get_username(conn)?
          let response = build_feed_response(username)
          conn.write(response)
        end

      | "SEND_MESSAGE" =>
        if parts.size() >= 3 then
          try
            let sender = _get_username(conn)?
            let recipient = parts(1)?
            let content = _decode_text(parts(2)?)
            _engine.send_direct_message(sender, recipient, content)
            conn.write("MESSAGE_SENT")
          end
        end

      | "REPLY_MESSAGE" =>
        if parts.size() >= 3 then
          try
            let username = _get_username(conn)?
            let message_id = parts(1)?
            let content = _decode_text(parts(2)?)
            let user = _engine.users(username)?
            user.reply_to_message(message_id, content)
            conn.write("MESSAGE_SENT")
          end
        end
      | "VOTE_POST" =>
        if parts.size() >= 4 then
          try
            let username = _get_username(conn)?
            let subreddit = parts(1)?
            let post_index = parts(2)?.usize()?
            let is_upvote = parts(3)? == "UPVOTE"
            _engine.vote_on_post(username, subreddit, post_index, is_upvote)
            conn.write("VOTE_OK")
          end
        end
      | "VOTE_COMMENT" =>
        if parts.size() >= 5 then
          try
            let username = _get_username(conn)?
            let subreddit = parts(1)?
            let post_index = parts(2)?.usize()?
            let comment_index = parts(3)?.usize()?
            let is_upvote = parts(4)? == "UPVOTE"
            _engine.vote_on_post(username, subreddit, post_index, is_upvote)
            conn.write("VOTE_OK")
          end
        end
     | "VIEW_PROFILE" =>
        try
          let username = _get_username(conn)?
          let user = _engine.users(username)?
          user.get_profile_data(conn, this)
          _env.out.print("Requested profile data for: " + username)
        end
      | "VIEW_METRICS" =>
        try
          let username = _get_username(conn)?
          let response = build_metrics_response()
          conn.write(response)
          _env.out.print("Sent metrics to: " + username)
        end
      end
      let end_time = Time.now()._2.f64() / 1_000_000.0
      _engine.track_response_time(end_time - start_time)
    else
      _env.out.print("Error processing message: " + String.from_array(data))
    end

  be build_profile_response(user: User tag, conn: TCPConnection tag) =>
    let response = recover iso String end
    response.append("PROFILE")
    
    // Instead of directly calling methods on user, we'll use behaviors
    user.get_profile_data(conn, this)

  be receive_profile_data(username: String, bio: String, join_date: I64, 
    post_karma: I64, comment_karma: I64, total_karma: I64, 
    subreddit_karma: String, achievements: String, conn: TCPConnection tag) =>
    let response = recover iso String end
    response.append("PROFILE")
    response.append(" ###PROFILE### Username " + username)
    response.append(" ###PROFILE### Bio " + bio)
    response.append(" ###PROFILE### Join_Date " + join_date.string())
    response.append(" ###PROFILE### Post_Karma " + post_karma.string())
    response.append(" ###PROFILE### Comment_Karma " + comment_karma.string())
    response.append(" ###PROFILE### Total_Karma " + total_karma.string())
    
    if subreddit_karma != "" then
      response.append(" ###PROFILE### Subreddit_Karma " + subreddit_karma)
    end
    
    if achievements != "" then
      response.append(" ###PROFILE### Achievements " + achievements)
    end
    
    conn.write(consume response)


  fun ref build_metrics_response(): String val =>
    _engine.get_metrics_string()

  fun ref build_comments_response(subreddit: String, post_index: USize): String =>
    try
      let response = recover iso String end
      response.append("COMMENTS")

      let subreddit_obj = _engine.subreddits(subreddit)?
      let post = subreddit_obj.get_posts()(post_index)?
      let comments = post.get_comments()

      for comment in comments.values() do
        response.append(" ###COMMENT###")
        response.append(" " + comment.get_author())
        response.append(" " + comment.get_content().clone().>replace(" ", "_"))
      end
      
      consume response
    else
      "COMMENTS"
    end
    
  be closed(conn: TCPConnection tag) =>
    _connections.unset(conn)
    for (username, connection) in _usernames.pairs() do
      if connection is conn then
        try _usernames.remove(username)? end
      end
    end
    _env.out.print("Client disconnected")
    
  be connect_failed(conn: TCPConnection tag) =>
    _env.out.print("Connection failed")

  fun _get_username(conn: TCPConnection tag): String ? =>
    """
    Get username associated with a connection
    """
    for (username, connection) in _usernames.pairs() do
      if connection is conn then
        return username
      end
    end
    error

  fun ref build_posts_response(): String =>
    let response = recover iso String end
    response.append("POST_LIST")

    for (subreddit_name, subreddit) in _engine.subreddits.pairs() do
      for post in subreddit.get_posts().values() do
        response.append(" ###POST###")
        response.append(" " + post.title.clone().>replace(" ", "_"))
        response.append(" " + post.author)
        response.append(" " + post.content.clone().>replace(" ", "_"))
      end
    end
      
    consume response

  fun ref build_subreddits_response(): String =>
    let response = recover iso String end
    response.append("SUBREDDIT_LIST")
    
    for subreddit_name in _engine.subreddits.keys() do
      response.append(" " + subreddit_name)
    end
      
    consume response

  fun ref build_joined_subreddits_response(username: String): String =>
    let response = recover iso String end
    response.append("SUBREDDIT_LIST")
    
    for (name, subreddit) in _engine.subreddits.pairs() do
      if subreddit.get_members().contains(username) then
        response.append(" " + name)
      end
    end
    
    consume response

  fun ref build_feed_response(username: String): String =>
    let response = recover iso String end
    response.append("POST_LIST")
    
    for (name, subreddit) in _engine.subreddits.pairs() do
      if subreddit.get_members().contains(username) then
        var post_count: USize = 0
        for post in subreddit.get_posts().values() do
          if post_count >= 10 then break end
          response.append(" ###POST###")
          response.append(" " + post.title.clone().>replace(" ", "_"))
          response.append(" " + post.author)
          response.append(" " + post.content.clone().>replace(" ", "_"))
          response.append(" " + name)
          post_count = post_count + 1
        end
      end
    end
    
    consume response

  fun get_connection_stats(): (USize, USize) =>
    var online: USize = 0
    var offline = _simulated_offline_users.size()
    
    for username in _engine.users.keys() do
      if not _usernames.contains(username) and 
         not _simulated_offline_users.contains(username) then
        online = online + 1
      end
    end
    
    (online, offline)

be simulate_activity() =>
    try
      // Create arrays of users and subreddits for random selection
      let user_array = Array[String]
      for username in _engine.users.keys() do
        // Only include simulated users (those without real connections)
        if not _usernames.contains(username) then
          user_array.push(username)
        end
      end

      // Connection state changes - rare (1% chance per user)
      for username in user_array.values() do
        if _rand.real() < 0.01 then
          if _simulated_offline_users.contains(username) then
            _simulated_offline_users.unset(username)
            _engine.track_connection_change(username, true)
            _env.out.print("Simulation: " + username + " came online")
          else
            _simulated_offline_users.set(username)
            _engine.track_connection_change(username, false)
            _env.out.print("Simulation: " + username + " went offline")
          end
        end
      end

      // Each online user has a chance to perform an action
      for username in user_array.values() do
        if not _simulated_offline_users.contains(username) then
          // 20% chance for a user to be active in this cycle
          if _rand.real() < 0.2 then
            let user_subreddits = Array[String]
            for (name, subreddit) in _engine.subreddits.pairs() do
              if subreddit.get_members().contains(username) then
                user_subreddits.push(name)
              end
            end
        
            if user_subreddits.size() > 0 then
              let subreddit_idx = _rand.int(user_subreddits.size().u64()).usize()
              let active_subreddit = user_subreddits(subreddit_idx)?
              let subreddit = _engine.subreddits(active_subreddit)?

              match _rand.real()
              | let x: F64 if x < 0.05 =>
                // Create post (5% chance when active)
                let title = recover val "Post about " + active_subreddit + " " + Time.now()._1.string() end
                let content = recover val "Sharing thoughts about " + active_subreddit end
                _engine.create_post(username, active_subreddit, consume title, consume content)
                _env.out.print("Simulation: " + username + " created a post in " + active_subreddit)

              | let x: F64 if x < 0.08 =>
                // Repost (3% chance when active)
                let other_subreddits = Array[String]
                for (name, sub) in _engine.subreddits.pairs() do
                  if (name != active_subreddit) and sub.get_members().contains(username) then
                    other_subreddits.push(name)
                  end
                end

                if (other_subreddits.size() > 0) and (subreddit.get_posts().size() > 0) then
                  let target_idx = _rand.int(other_subreddits.size().u64()).usize()
                  let post_idx = _rand.int(subreddit.get_posts().size().u64()).usize()
                  try
                    let target_subreddit = other_subreddits(target_idx)?
                    _engine.repost(active_subreddit, post_idx, target_subreddit, username)
                    _env.out.print("Simulation: " + username + " reposted from r/" + 
                      active_subreddit + " to r/" + target_subreddit)
                  end
                end

              | let x: F64 if x < 0.85 =>
                // Most likely to interact with existing content (77% chance when active)
                let posts = subreddit.get_posts()
                if posts.size() > 0 then
                  let post_idx = _rand.int(posts.size().u64()).usize()
                  try 
                    match _rand.real()
                    | let y: F64 if y < 0.2 =>
                      // Comment (20% of interactions)
                      let comment = recover val "Commenting about post #" + post_idx.string() end
                      _engine.add_comment(username, active_subreddit, post_idx, consume comment)
                      _env.out.print("Simulation: " + username + " commented on post " + post_idx.string() + " in " + active_subreddit)
                    | let y: F64 if y < 0.9 =>
                      // Vote (70% of interactions)
                      let is_upvote = _rand.real() < 0.8
                      _engine.vote_on_post(username, active_subreddit, post_idx, is_upvote)
                      _env.out.print("Simulation: " + username + 
                        (if is_upvote then " upvoted " else " downvoted " end) + 
                        "post " + post_idx.string() + " in " + active_subreddit)
                    else
                      // Direct message (10% of interactions)
                      let post = posts(post_idx)?
                      if post.author != username then
                        let message = recover val "About post #" + post_idx.string() + " in " + active_subreddit end
                        _engine.send_direct_message(username, post.author, consume message)
                        _env.out.print("Simulation: " + username + " messaged " + post.author + " about post " + post_idx.string())
                      end
                    end
                  end
                end

              else
                // Join/leave subreddits (15% chance when active)
                if _rand.real() < 0.9 then
                  if not subreddit.get_members().contains(username) then
                    _engine.join_subreddit(username, active_subreddit)
                    _env.out.print("Simulation: " + username + " joined " + active_subreddit)
                  end
                else
                  if subreddit.get_members().size() > 1 then
                    _engine.leave_subreddit(username, active_subreddit)
                    _env.out.print("Simulation: " + username + " left " + active_subreddit)
                  end
                end
              end
            end
          end
        end
      end

      // New user creation (10% chance per cycle)
      if _rand.real() < 0.10 then
        let new_username = recover val "User_" + Time.now()._1.string() end
        _engine.register_user(new_username)
        _engine.track_new_simulated_user(new_username)
        // 20% chance to start offline
        if _rand.real() < 0.2 then 
          _simulated_offline_users.set(new_username)
          _engine.track_connection_change(new_username, false)
          _env.out.print("Simulation: New user registered: " + new_username + " (offline)")
        else
          _env.out.print("Simulation: New user registered: " + new_username + " (online)")
        end

        let subreddit_array = Array[String]
        for name in _engine.subreddits.keys() do
          subreddit_array.push(name)
        end
        
        if subreddit_array.size() > 0 then
          let distribution = ZipfDistribution.distribute_users(1, subreddit_array.size(), 1.2, _rand)
          for i in Range(0, distribution.size()) do
            try
              if distribution(i)? > 0 then
                _engine.join_subreddit(new_username, subreddit_array(i)?)
                _env.out.print("Simulation: " + new_username + " joined " + subreddit_array(i)?)
              end
            end
          end
        end
      end

      // New subreddit creation (0.5% chance per cycle)
      if _rand.real() < 0.005 then
        let new_subreddit_name = recover val "Subreddit_" + Time.now()._1.string() end
        _engine.create_subreddit(new_subreddit_name)
        _env.out.print("Simulation: New subreddit created: " + new_subreddit_name)

        // Existing users join new subreddit (1% chance per user)
        for username in _engine.users.keys() do
          if _rand.real() < 0.01 then
            _engine.join_subreddit(username, new_subreddit_name)
            _env.out.print("Simulation: " + username + " joined new subreddit " + new_subreddit_name)
          end
        end
      end
    end