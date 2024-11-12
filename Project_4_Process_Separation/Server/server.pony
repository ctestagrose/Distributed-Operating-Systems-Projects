use "net"
use "collections"
use "../Engine"

actor RedditServer is ServerNotify
  let _env: Env
  let _auth: TCPListenAuth
  let _engine: RedditEngine
  let _connections: SetIs[TCPConnection tag] // Using SetIs instead of Map for connections
  let _usernames: Map[String, TCPConnection tag] // Username -> Connection mapping
  
  new create(env: Env, auth: TCPListenAuth) =>
    _env = env
    _auth = auth
    _engine = RedditEngine(env)
    _connections = SetIs[TCPConnection tag]
    _usernames = Map[String, TCPConnection tag]
    
    TCPListener(auth, recover ServerListener(this, env) end, "localhost", "8989")
    
  be connected(conn: TCPConnection tag) =>
    _connections.set(conn)
    _env.out.print("New client connected")
    
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
        
      | "POST" =>
        if parts.size() >= 4 then
          try
            let username = _get_username(conn)?
            let subreddit = parts(1)?
            let title = parts(2)?
            let content = parts(3)?
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
      end
    else
      _env.out.print("Error processing message: " + String.from_array(data))
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
          response.append(" " + post.title)
          response.append(" " + post.author)
          response.append(" " + post.content)
        end
    end
      
    consume response

