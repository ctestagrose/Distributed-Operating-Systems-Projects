use "net"
use "collections"
use "format"
use "../Engine"

primitive GET
primitive POST
primitive PUT
primitive DELETE

type Method is (GET | POST | PUT | DELETE)


actor HTTPServer
  let _env: Env
  let _auth: TCPListenAuth
  let _connections: SetIs[TCPConnection tag]
  let _routes: Array[Route]
  let _reddit_engine: RedditEngineWrapper
  
  new create(env: Env, auth: TCPListenAuth) =>
    _env = env
    _auth = auth
    _connections = SetIs[TCPConnection tag]
    _reddit_engine = RedditEngineWrapper(env)
    _routes = Array[Route]

    initialize_routes()
    
    TCPListener(auth, recover HTTPServerListener(this, env) end, "localhost", "8080")
    
  fun ref initialize_routes() =>
    _routes.push(Route(POST, "/users", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        _env.out.print("Processing /users request")
        _env.out.print("Request body: " + request.body)
        
        let json = JsonParser.parse(request.body, _env)?
        _env.out.print("JSON parsed successfully")
        
        let username = json("username")? as String
        let bio = try json("bio")? as String else "" end
        
        _env.out.print("Extracted username: " + username + ", bio: " + bio)
        _reddit_engine.register_user(username, bio)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(201, headers, "{\"status\":\"success\",\"message\":\"User created\"}\n")
      else
        _env.out.print("Failed to process user registration request")
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request body\"}\n")
      end
    }))

    _routes.push(Route(POST, "/subreddits/:name/subscribe", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        _env.out.print("Processing subreddit subscription request")
        _env.out.print("Request body: " + request.body)
        
        let subreddit_name = params("name")?
        _env.out.print("Subreddit name from params: " + subreddit_name)
        
        let json = JsonParser.parse(request.body, _env)?
        _env.out.print("JSON parsed successfully")
        
        let username = json("username")? as String
        _env.out.print("Username extracted: " + username)
        
        _reddit_engine.join_subreddit_with_verification(username, subreddit_name, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        _env.out.print("Failed to process subreddit subscription request")
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    _routes.push(Route(POST, "/subreddits/:name/posts", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let subreddit_name = params("name")?
        let json = JsonParser.parse(request.body, _env)?
        let username = json("username")? as String
        let title = json("title")? as String
        let content = json("content")? as String
        
        _reddit_engine.create_post(username, subreddit_name, title, content)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(201, headers, "{\"status\":\"success\",\"message\":\"Post created\"}\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    _routes.push(Route(GET, "/subreddits", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
        _reddit_engine.get_all_subreddits(conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
    }))

    _routes.push(Route(GET, "/posts", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
        _reddit_engine.get_all_posts(conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
    }))


    _routes.push(Route(GET, "/posts/:id", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let post_id = params("id")?.usize()?
        let post = _reddit_engine.get_post(post_id, conn)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(404, headers, "{\"error\":\"Post not found\"}\n")
      end
    }))

    _routes.push(Route(POST, "/posts/:id/vote", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let post_id = params("id")?.usize()?
        let json = JsonParser.parse(request.body, _env)?
        let username = json("username")? as String
        let subreddit = json("subreddit")? as String
        let is_upvote = json("upvote")? as Bool
        
        _reddit_engine.vote_on_post(username, subreddit, post_id, is_upvote)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(200, headers, "{\"status\":\"success\",\"message\":\"Vote recorded\"}\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))


    _routes.push(Route(POST, "/posts/:id/comments", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let post_id = params("id")?.usize()?
        let json = JsonParser.parse(request.body, _env)?
        let username = json("username")? as String
        let content = json("content")? as String
        let subreddit = json("subreddit")? as String
        
        _reddit_engine.add_comment(username, subreddit, post_id, content)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(201, headers, "{\"status\":\"success\",\"message\":\"Comment added\"}\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))
    
    _routes.push(Route(GET, "/posts/:id/comments", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let post_id = params("id")?.usize()?
        _reddit_engine.get_post_with_comments(post_id, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    _routes.push(Route(POST, "/comments/:id/vote", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let comment_id = params("id")?.usize()?
        let json = JsonParser.parse(request.body, _env)?
        let username = json("username")? as String
        let subreddit = json("subreddit")? as String
        let post_id = json("post_id")? as String
        let is_upvote = json("upvote")? as Bool
        
        _reddit_engine.vote_on_comment(username, subreddit, post_id.usize()?, comment_id, is_upvote)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(200, headers, "{\"status\":\"success\",\"message\":\"Vote recorded\"}\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    _routes.push(Route(GET, "/subreddits/:name/feed/:sort", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let subreddit_name = params("name")?
        let sort = params("sort")?
        let sort_type = match sort
          | "hot" => SortType.hot()
          | "new" => SortType.new_p()
          | "controversial" => SortType.controversial() 
          | "top" => SortType.top()
        else
          SortType.hot()
        end
        
        _reddit_engine.get_sorted_subreddit_feed(subreddit_name, sort_type, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(404, headers, "{\"error\":\"Subreddit not found\"}\n")
      end
    }))

    _routes.push(Route(GET, "/feed/subscribed", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let username = request.headers("Username")?
        
        _reddit_engine.get_user_subscribed_feed(username, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Username not provided\"}\n")
      end
    }))

    _routes.push(Route(GET, "/subreddits/:name/:sort", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let subreddit_name = params("name")?
        let sort_type = match params("sort")?
        | "hot" => SortType.hot()
        | "new" => SortType.new_p()
        | "controversial" => SortType.controversial()
        | "top" => SortType.top()
        else
          SortType.hot()
        end
        
        _reddit_engine.get_sorted_subreddit_feed(subreddit_name, sort_type, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(404, headers, "{\"error\":\"Invalid subreddit or sort type\"}\n")
      end
    }))

    _routes.push(Route(GET, "/subreddits/:name/posts", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let subreddit_name = params("name")?
        _reddit_engine.get_subreddit_posts(subreddit_name, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(404, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    _routes.push(Route(GET, "/users/:username/messages", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let username = params("username")?
        _reddit_engine.get_user_messages(username, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    _routes.push(Route(GET, "/messages/:thread_id", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let thread_id = params("thread_id")?
        let username = request.headers("Username")?
        _reddit_engine.get_message_thread(username, thread_id, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    _routes.push(Route(POST, "/messages", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let json = JsonParser.parse(request.body, _env)?
        let from_username = json("from")? as String
        let to_username = json("to")? as String
        let content = json("content")? as String
        let thread_id = try json("thread_id")? as String else "" end
        
        _reddit_engine.send_message(from_username, to_username, content, thread_id, conn)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(201, headers, "{\"status\":\"success\",\"message\":\"Message sent\"}\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

  be connected(conn: TCPConnection tag) =>
    _connections.set(conn)
    _env.out.print("New connection")
    
  be received(conn: TCPConnection tag, data: Array[U8] val) =>
    _env.out.print("Received raw data: " + String.from_array(data))
    try
      let request = _parse_request(data)?
      let response = _handle_request(request, conn)
      _env.out.print("Sending response:\n" + response.string())
      conn.write(response.string())
    else
      let headers = recover val Map[String, String] end
      let response = HTTPResponse(400, headers, "Bad Request\n")
      conn.write(response.string())
    end

  fun _handle_request(request: HTTPRequest, conn: TCPConnection tag): HTTPResponse =>
    for route in _routes.values() do
      (let matches, let response) = route.matches(request, conn)
      if matches then
        return response
      end
    end
    
    let headers = recover val Map[String, String] end
    HTTPResponse(404, headers, "Not Found\n")

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
    
  be closed(conn: TCPConnection tag) =>
    _connections.unset(conn)
    _env.out.print("Connection closed")
  
fun _parse_request(data: Array[U8] val): HTTPRequest ? =>
    let request_str = String.from_array(data)
    var header_end: ISize = -1

      let search = "\r\n\r\n"
      var i: ISize = 0
      while i < (request_str.size().isize() - 3) do
        if (request_str.substring(i, i + 4) == search) then
          header_end = i
          break
        end
        i = i + 1
      end

    
    if header_end == -1 then
      _env.out.print("No header boundary found")
      error
    end
    
    let header_section = recover val
      request_str.substring(0, header_end)
    end
    
    let body = recover val
      request_str.substring(header_end + 4)
    end
    
    let header_lines = header_section.split("\r\n")
    if header_lines.size() == 0 then 
      _env.out.print("No headers found")
      error 
    end
    
    let request_line = try
      header_lines(0)?.split(" ")
    else
      _env.out.print("Invalid request line")
      error
    end
    
    if request_line.size() < 2 then 
      _env.out.print("Invalid request line format")
      error 
    end
    
    let method_str = request_line(0)?
    let path = request_line(1)?
    
    let method = match method_str
    | "GET" => GET
    | "POST" => POST
    | "PUT" => PUT
    | "DELETE" => DELETE
    else
      _env.out.print("Invalid method: " + method_str)
      error
    end
    
    let headers = recover trn Map[String, String] end
    for j in Range(1, header_lines.size()) do
      try
        let line = header_lines(j)?
        let header_parts = line.split(": ", 2)
        if header_parts.size() == 2 then
          let key = header_parts(0)?
          let value = header_parts(1)?
          headers(key) = value
        end
      end
    end
    
    HTTPRequest(method, path, consume headers, consume body)


class HTTPServerListener is TCPListenNotify
  let _server: HTTPServer
  let _env: Env
  
  new iso create(server: HTTPServer, env: Env) =>
    _server = server
    _env = env
  
  fun ref listening(listen: TCPListener ref) =>
    try
      (let host, let service) = listen.local_address().name()?
      _env.out.print("Listening on " + host + ":" + service)
    else
      _env.out.print("Listening on unknown address")
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _env.out.print("Failed to listen")

  fun ref closed(listen: TCPListener ref) =>
    _env.out.print("Listener closed")

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    HTTPServerConnection(_server)

class HTTPServerConnection is TCPConnectionNotify
  let _server: HTTPServer
  
  new iso create(server: HTTPServer) =>
    _server = server
  
  fun ref accepted(conn: TCPConnection ref) =>
    _server.connected(conn)
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _server.received(conn, consume data)
    true
  
  fun ref closed(conn: TCPConnection ref) =>
    _server.closed(conn)
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    None


actor Main
  new create(env: Env) =>
    let auth = TCPListenAuth(env.root)
    let http_server = HTTPServer(env, auth)