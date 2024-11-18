use "net"
use "collections"
use "../Engine"
use "time"
use "random"

class SimulationUpdate is TimerNotify
  let _server: RedditServer
  
  new iso create(server: RedditServer) =>
    _server = server
    
  fun ref apply(timer: Timer, count: U64): Bool =>
    _server.simulate_activity()
    true  // Continue repeating
    
  fun ref cancel(timer: Timer) =>
    None

actor RedditServer is ServerNotify
  let _env: Env
  let _auth: TCPListenAuth
  let _engine: RedditEngine
  let _connections: SetIs[TCPConnection tag] // Using SetIs instead of Map for connections
  let _usernames: Map[String, TCPConnection tag] // Username -> Connection mapping
  let _rand: Rand

  new create(env: Env, auth: TCPListenAuth) =>
    _env = env
    _auth = auth
    _engine = RedditEngine(env)
    _connections = SetIs[TCPConnection tag]
    _usernames = Map[String, TCPConnection tag]
    _rand = Rand(Time.now()._2.u64())

    _engine.run(1000)
    
    TCPListener(auth, recover ServerListener(this, env) end, "localhost", "8989")

    let timers = Timers
    let timer = Timer(SimulationUpdate(this),
      5_000_000_000, // 5 seconds
      5_000_000_000) // 5 seconds between updates
    timers(consume timer)
    
  be connected(conn: TCPConnection tag) =>
    _connections.set(conn)
    _env.out.print("New client connected")

  fun _decode_text(text: String): String =>
    text.clone().>replace("_", " ")
    
   be received(conn: TCPConnection tag, data: Array[U8] val) =>
    try
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
            _env.out.print("Subreddit created: " + subreddit_name + " by " + username)
          end
        end
      end
    else
      _env.out.print("Error processing message: " + String.from_array(data))
    end

  fun ref build_comments_response(subreddit: String, post_index: USize): String =>
    try
      let response = recover iso String end
      response.append("COMMENTS")

      let subreddit_obj = _engine.subreddits(subreddit)?
      let post = subreddit_obj.get_posts()(post_index)?
      let comments = post.get_comments()

      for comment in comments.values() do
        response.append(" " + comment.get_author())
        response.append(" " + comment.get_content())
      end
      
      consume response
    else
      "COMMENTS" // Empty list if error
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
        // Add a separator between posts
        response.append(" ###POST###")
        // Encode the fields to handle spaces
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

  be simulate_activity() =>
    try
      // Get random users for activity
      let users = _engine.users.keys()
      let random_user = users.next()?
      let another_user = users.next()?
      
      // Simulate random activities
      match _rand.int(5)
      | 0 => // Create a post
        let title = recover val "Simulated Post " + Time.now()._1.string() end
        let content = recover val "This is simulated content created at " + Time.now()._1.string() end
        _engine.create_post(random_user, "programming", consume title, consume content)
        _env.out.print("Simulation: " + random_user + " created a post")
        
      | 1 => // Add a comment
        let comment = recover val "Simulated comment at " + Time.now()._1.string() end
        _engine.add_comment(random_user, "programming", 0, consume comment)
        _env.out.print("Simulation: " + random_user + " added a comment")
        
      | 2 => // Vote on something
        _engine.vote_on_post(random_user, "programming", 0, true)
        _env.out.print("Simulation: " + random_user + " voted on a post")
        
      | 3 => // Send a message
        let message = recover val "Simulated message at " + Time.now()._1.string() end
        _engine.send_direct_message(random_user, another_user, consume message)
        _env.out.print("Simulation: " + random_user + " sent a message to " + another_user)
        
      | 4 => // Create a new subreddit
        let subreddit_name = recover val "SimulatedSubreddit" + Time.now()._1.string() end
        let subreddit_val = subreddit_name.clone()
        _engine.create_subreddit(consume subreddit_val)
        _engine.join_subreddit(random_user, consume subreddit_name)
        _env.out.print("Simulation: " + random_user + " created a new subreddit")
      end
    end
