use "net"
use "collections"
use "format"
use "../Engine"

primitive GET
primitive POST
primitive PUT
primitive DELETE

type Method is (GET | POST | PUT | DELETE)

actor RedditEngineWrapper
  let _engine: RedditEngine ref
  let _env: Env
  
  new create(env: Env) =>
    _env = env
    _engine = RedditEngine(env)
    
    // Initialize default subreddits
    let default_subreddits = [
      "programming"
      "news"
      "funny" 
      "science"
      "gaming"
      "movies"
      "music" 
      "books"
      "technology"
      "sports"
      "cats"
      "pics"
      "cars"
      "memes"
      "politics"
      "history"
      "jokes"
      "math"
      "music"
      "stocks"
    ]
    
  for name in default_subreddits.values() do
    _engine.create_subreddit(name)
    _env.out.print("Created subreddit: " + name)
  end

  // Create test user and add sample posts
  _engine.register_user("system_bot", "A bot that creates initial content")
  _engine.join_subreddit("system_bot", "programming")
  
  match _engine.create_post("system_bot", "programming", 
    "Intro to Pony Programming", 
    "Pony is an actor-model language focusing on safety and performance.")
  | None => _env.out.print("Failed to create initial post")
  end
  
  match _engine.create_post("system_bot", "programming",
    "Understanding Reference Capabilities",
    "Reference capabilities are key to Pony's concurrency model.")
  | None => _env.out.print("Failed to create initial post")
  end
  
  match _engine.create_post("system_bot", "programming",
    "Actor Communication Patterns",
    "Best practices for message passing between actors in distributed systems.")
  | None => _env.out.print("Failed to create initial post")
  end

  _env.out.print("Initialized test content")
  
  be register_user(username: String, bio: String) =>
    _engine.register_user(username, bio)
    
  be join_subreddit(username: String, subreddit: String) =>
    _engine.join_subreddit(username, subreddit)

  be create_subreddit(name: String) =>
    _env.out.print("Creating subreddit: " + name)
    _engine.create_subreddit(name)
    
  be create_post(username: String, subreddit: String, title: String, content: String) =>
    _engine.create_post(username, subreddit, title, content)
    
  be vote_on_post(username: String, subreddit: String, post_index: USize, is_upvote: Bool) =>
    _engine.vote_on_post(username, subreddit, post_index, is_upvote)

  be add_comment(username: String, subreddit: String, post_id: USize, content: String) =>
    _env.out.print("Adding comment from " + username + " to post " + post_id.string())
    _engine.add_comment(username, subreddit, post_id, content)


  be get_all_posts(conn: TCPConnection tag) =>
    let feed = _engine.get_popular_feed()
    let response = JsonBuilder.feed_to_json(feed)
    
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let http_response = HTTPResponse(200, headers, response)
    conn.write(http_response.string())

  be vote_on_comment(username: String, subreddit: String, post_id: USize, 
    comment_id: USize, is_upvote: Bool) =>
    _engine.vote_on_comment(username, subreddit, post_id, comment_id, is_upvote)
    _env.out.print("Processed vote on comment " + comment_id.string())

  be get_post(post_id: USize, conn: TCPConnection tag) =>
    // Search through all subreddits to find the post
    for (subreddit_name, subreddit) in _engine.subreddits.pairs() do
      try
        let post = _engine.get_post(post_id, subreddit_name)?
        let response = JsonBuilder.post_with_comments(post)
        conn.write(response)
        return
      end
    end
    // If we get here, post wasn't found
    let headers = recover val Map[String, String] end
    let error_response = HTTPResponse(404, headers, "{\"error\":\"Post not found\"}\n")
    conn.write(error_response.string())

  be get_popular_feed(conn: TCPConnection tag) =>
    let feed = _engine.get_popular_feed()
    let response = JsonBuilder.feed_to_json(feed)
    conn.write(response)

  be get_sorted_subreddit_feed(subreddit: String, sort_type: U8, conn: TCPConnection tag) =>
    try
      _env.out.print("Getting feed for subreddit: " + subreddit)
      let feed = _engine.get_subreddit_feed(subreddit, sort_type)?
      _env.out.print("Got feed with " + feed.posts.size().string() + " posts")
      
      let response_body = JsonBuilder.feed_to_json(feed)
      _env.out.print("Generated JSON response: " + response_body)
      
      let headers = recover val 
        let map = Map[String, String]
        map("Content-Type") = "application/json"
        map
      end
      
      let http_response = HTTPResponse(200, headers, response_body)
      conn.write(http_response.string())
    else
      _env.out.print("Error getting subreddit feed")
      let headers = recover val 
        let map = Map[String, String]
        map("Content-Type") = "application/json"
        map
      end
      let error_response = HTTPResponse(404, headers, "{\"error\":\"Subreddit not found or error getting feed\"}\n")
      conn.write(error_response.string())
    end

  be get_subreddit_posts(subreddit: String, conn: TCPConnection tag) =>
    try
      let feed = _engine.get_subreddit_feed(subreddit, SortType.hot())?
      let response = recover iso String end
      response.append("{\"posts\":[")
      
      var first = true
      for post in feed.posts.values() do
        if not first then response.append(",") end
        response.append("{")
        response.append("\"title\":\"" + post.title + "\",")
        response.append("\"author\":\"" + post.author + "\",")
        response.append("\"content\":\"" + post.content + "\",")
        response.append("\"score\":" + post.get_score().string())
        response.append("}")
        first = false
      end
      
      response.append("]}")
      
      let headers = recover val 
        let map = Map[String, String]
        map("Content-Type") = "application/json"
        map
      end
      
      let http_response = HTTPResponse(200, headers, consume response)
      conn.write(http_response.string())
    else
      let headers = recover val Map[String, String] end
      let error_response = HTTPResponse(404, headers, "{\"error\":\"Subreddit not found\"}\n")
      conn.write(error_response.string())
    end

  be get_all_subreddits(conn: TCPConnection tag) =>
    let response = recover iso String end
    response.append("{\"subreddits\":[")
    
    var first = true
    for (name, subreddit) in _engine.subreddits.pairs() do
      if not first then response.append(",") end
      response.append("{")
      response.append("\"name\":\"" + name + "\",")
      response.append("\"memberCount\":" + subreddit.get_member_count().string() + ",")
      response.append("\"postCount\":" + subreddit.get_posts().size().string() + ",")
      
      // Calculate total engagement (comments + votes across all posts)
      var total_comments: USize = 0
      var total_votes: USize = 0
      for post in subreddit.get_posts().values() do
        total_comments = total_comments + post.get_comments().size()
        total_votes = total_votes + post.upvotes.size() + post.downvotes.size()
      end
      
      response.append("\"totalComments\":" + total_comments.string() + ",")
      response.append("\"totalVotes\":" + total_votes.string())
      response.append("}")
      first = false
    end
    
    response.append("]}")

    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let http_response = HTTPResponse(200, headers, consume response)
    conn.write(http_response.string())



primitive JsonBuilder
  fun feed_to_json(feed: PostFeed): String =>
      let response = recover iso String end
      response.append("{\"posts\":[")
      
      var first = true
      for post in feed.posts.values() do
        if not first then response.append(",") end
        response.append("{")
        response.append("\"id\":" + post.id.string() + ",")  // Use internal ID instead of timestamp
        response.append("\"title\":\"" + post.title + "\",")
        response.append("\"author\":\"" + post.author + "\",")
        response.append("\"content\":\"" + post.content + "\",")
        response.append("\"score\":" + post.get_score().string() + ",")
        response.append("\"upvotes\":" + post.upvotes.size().string() + ",")
        response.append("\"downvotes\":" + post.downvotes.size().string() + ",")
        response.append("\"commentCount\":" + post.get_comments().size().string())
        response.append("}")
        first = false
      end
      
      response.append("]}")
      consume response

  fun post_to_json(post: RedditPost): String val =>
    let json = recover iso String end
    json.append("{")
    json.append("\"id\":" + post.id.string() + ",")  // Use internal ID
    json.append("\"title\":\"" + post.title + "\",")
    json.append("\"author\":\"" + post.author + "\",")
    json.append("\"content\":\"" + post.content + "\",")
    json.append("\"score\":" + post.get_score().string() + ",")
    json.append("\"upvotes\":" + post.upvotes.size().string() + ",")
    json.append("\"downvotes\":" + post.downvotes.size().string() + ",")
    json.append("\"commentCount\":" + post.get_comments().size().string() + ",")
    json.append("\"hotScore\":" + post.get_hot_score().string() + ",")
    json.append("\"controversyScore\":" + post.get_controversy_score().string() + ",")
    json.append("\"comments\":" + comments_to_json(post.get_comments()))
    json.append("}")
    consume json

  fun post_with_comments(post: RedditPost): String val =>
    let json = recover iso String end
    json.append("{")
    json.append("\"post\":" + post_to_json(post) + ",")
    json.append("\"comments\":" + comments_to_json(post.get_comments()))
    json.append("}")
    consume json

  fun comments_to_json(comments: Array[Comment] ref): String val =>
    let json = recover iso String end
    json.append("[")
    var first = true
    for comment in comments.values() do
      if not first then json.append(",") end
      json.append(comment_to_json(comment))
      first = false
    end
    json.append("]")
    consume json

  fun comment_to_json(comment: Comment): String val =>
    let json = recover iso String end
    json.append("{")
    json.append("\"author\":\"" + comment.get_author() + "\",")
    json.append("\"content\":\"" + comment.get_content() + "\",")
    json.append("\"score\":" + comment.get_score().string() + ",")
    json.append("\"upvotes\":" + comment.upvotes.size().string() + ",")
    json.append("\"downvotes\":" + comment.downvotes.size().string() + ",")
    json.append("\"replies\":" + comments_to_json(comment.get_replies()) + ",")
    json.append("\"created_at\":" + comment.created_at.string())
    json.append("}")
    consume json

class val RoutePattern
  let segments: Array[String] val
  let param_indices: Map[String, USize] val

  new val create(path: String) =>
    let segs = recover trn Array[String] end
    let params = recover trn Map[String, USize] end

    let parts = recover val path.split("/") end
    var idx: USize = 0
    try
      for i in Range(0, parts.size()) do
        let part = parts(i)?
        if part != "" then
          segs.push(part)
          if part.substring(0, 1) == ":" then
            params(part.substring(1)) = idx
          end
          idx = idx + 1
        end
      end
    end

    segments = consume segs
    param_indices = consume params

  fun matches(path: String): (Bool, Map[String, String] val) =>
    let params = recover trn Map[String, String] end
    let parts = recover val path.split("/") end
    let request_segments = recover trn Array[String] end

    try
      for i in Range(0, parts.size()) do
        let part = parts(i)?
        if part != "" then
          request_segments.push(part)
        end
      end
    end

    if request_segments.size() != segments.size() then
      (false, recover val Map[String, String] end)
    else
      try
        var is_match = true
        for i in Range(0, segments.size()) do
          let pattern_seg = segments(i)?
          let request_seg = request_segments(i)?

          if pattern_seg.substring(0, 1) == ":" then
            params(pattern_seg.substring(1)) = request_seg
          elseif pattern_seg != request_seg then
            is_match = false
            break
          end
        end
        (is_match, consume val params)
      else
        (false, recover val Map[String, String] end)
      end
    end

class val Route
  let method: Method
  let pattern: RoutePattern
  let handler: {(HTTPRequest, Map[String, String] val, TCPConnection tag): HTTPResponse} val

  new val create(method': Method, path: String, 
    handler': {(HTTPRequest, Map[String, String] val, TCPConnection tag): HTTPResponse} val) =>
    method = method'
    pattern = RoutePattern(path)
    handler = handler'

  fun matches(request: HTTPRequest, conn: TCPConnection tag): (Bool, HTTPResponse) =>
    (let is_match, let params) = pattern.matches(request.path)
    if (method is request.method) and is_match then
      (true, handler(request, params, conn))
    else
      (false, HTTPResponse(404, recover val Map[String, String] end, "Not Found\n"))
    end


class val HTTPRequest
  let method: Method
  let path: String
  let headers: Map[String, String] val
  let body: String
  
  new val create(method': Method, path': String, 
    headers': Map[String, String] val, body': String) =>
    method = method'
    path = path'
    headers = headers'
    body = body'

class val HTTPResponse
  let status: U16
  let headers: Map[String, String] val
  let body: String

  new val create(status': U16, headers': Map[String, String] val, body': String) =>
    status = status'
    headers = headers'
    body = body'

  fun string(): String =>
    let status_text = match status
      | 200 => "OK"
      | 201 => "Created"
      | 204 => "No Content"
      | 400 => "Bad Request"
      | 401 => "Unauthorized"
      | 404 => "Not Found"
      | 405 => "Method Not Allowed"
      | 500 => "Internal Server Error"
      else
        "Unknown"
      end

    let response = recover iso String end
    response.append("HTTP/1.1 " + status.string() + " " + status_text + "\r\n")

    // Default headers
    response.append("Connection: close\r\n")

    // Add custom headers
    for (name, value) in headers.pairs() do
      response.append(name + ": " + value + "\r\n")
    end

    // Add Content-Length
    response.append("Content-Length: " + body.size().string() + "\r\n")

    // Add Content-Type if not already present
    if not headers.contains("Content-Type") then
      response.append("Content-Type: text/plain\r\n")
    end

    response.append("\r\n")
    response.append(body)

    consume response

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
    // User routes
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

    // Subreddit creation routec
    _routes.push(Route(POST, "/subreddits", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let json = JsonParser.parse(request.body, _env)?
        let subreddit_name = json("name")? as String
        
        _reddit_engine.create_subreddit(subreddit_name)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(201, headers, "{\"status\":\"success\",\"message\":\"Subreddit created\"}\n")
      else
        _env.out.print("Failed to process subreddit creation request")
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request body\"}\n")
      end
    }))

    _routes.push(Route(GET, "/subreddits", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
        _reddit_engine.get_all_subreddits(conn)
        
        // Return empty response since actual response will be sent asynchronously
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
    }))

    // Subreddit subscribe route
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
        
        _reddit_engine.join_subreddit(username, subreddit_name)
        
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        HTTPResponse(200, headers, "{\"status\":\"success\",\"message\":\"Subscribed to subreddit\"}\n")
      else
        _env.out.print("Failed to process subreddit subscription request")
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "{\"error\":\"Invalid request\"}\n")
      end
    }))

    // Create post route
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

    // _routes.push(Route(GET, "/feed/subscribed", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
    //   try
    //     let username = request.headers("Username")?
    //     let all_posts = Array[(String, RedditPost)]  // Tuple of (subreddit_name, post)
        
    //     // Gather posts from all subreddits the user is subscribed to
    //     for (sub_name, subreddit) in _reddit_engine.subreddits.pairs() do
    //       if subreddit.get_members().contains(username) then
    //         for post in subreddit.get_posts().values() do
    //           all_posts.push((sub_name, post))
    //         end
    //       end
    //     end
        
    //     // Sort posts by hot score
    //     all_posts.>sort_by({(a: (String, RedditPost), b: (String, RedditPost)): Bool => 
    //       a._2.get_hot_score() > b._2.get_hot_score()
    //     })
        
    //     let feed = recover val
    //       let json = String
    //       json.append("{\"posts\":[")
    //       var first = true
    //       for (sub_name, post) in all_posts.values() do
    //         if not first then json.append(",") end
    //         json.append("{")
    //         json.append("\"subreddit\":\"" + sub_name + "\",")
    //         json.append("\"title\":\"" + post.title + "\",")
    //         json.append("\"author\":\"" + post.author + "\",")
    //         json.append("\"content\":\"" + post.content + "\",")
    //         json.append("\"score\":" + post.get_score().string() + ",")
    //         json.append("\"commentCount\":" + post.get_comments().size().string())
    //         json.append("}")
    //         first = false
    //       end
    //       json.append("]}")
    //       json
    //     end
        
    //     let headers = recover val 
    //       let map = Map[String, String]
    //       map("Content-Type") = "application/json"
    //       map
    //     end
        
    //     HTTPResponse(200, headers, feed)
    //   else
    //     let headers = recover val 
    //       let map = Map[String, String]
    //       map("Content-Type") = "application/json"
    //       map
    //     end
    //     HTTPResponse(400, headers, "{\"error\":\"Could not get subscribed feed\"}\n")
    //   end
    // }))

    _routes.push(Route(POST, "/posts/:id/vote", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let post_id = params("id")?.usize()?  // Parse ID as number
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

    // Get all posts
    _routes.push(Route(GET, "/posts", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
        _reddit_engine.get_all_posts(conn)
        
        // Return empty response since the actual response will be sent asynchronously
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
    }))


    // Get specific post with comments
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
          SortType.hot() // Default to hot
        end
        
        _reddit_engine.get_sorted_subreddit_feed(subreddit_name, sort_type, conn)
        
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "") // Response sent asynchronously
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(404, headers, "{\"error\":\"Subreddit not found\"}\n")
      end
    }))

    // Get subreddit posts with sort options
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
        
        // Return empty 200 response - actual content will be sent async
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(404, headers, "{\"error\":\"Invalid subreddit or sort type\"}\n")
      end
    }))

    _routes.push(Route(POST, "/posts/:id/comments", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let post_id = params("id")?.usize()?  // This will parse the ID as a number
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

    // Get posts route
    _routes.push(Route(GET, "/subreddits/:name/posts", {(request: HTTPRequest, params: Map[String, String] val, conn: TCPConnection tag): HTTPResponse =>
      try
        let subreddit_name = params("name")?
        _reddit_engine.get_subreddit_posts(subreddit_name, conn)
        
        // Return empty response since actual response will be sent asynchronously
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(404, headers, "{\"error\":\"Invalid request\"}\n")
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
    _env.out.print("Parsing request: " + request_str)
    
    // Find the first empty line boundary
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
    
    // Extract headers and body with proper reference capabilities
    let header_section = recover val
      request_str.substring(0, header_end)
    end
    
    let body = recover val
      request_str.substring(header_end + 4)
    end
    
    _env.out.print("Headers:\n" + header_section.clone())
    _env.out.print("Body:\n" + body.clone())
    
    let header_lines = header_section.split("\r\n")
    if header_lines.size() == 0 then 
      _env.out.print("No headers found")
      error 
    end
    
    // Parse request line
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
    
    // Parse headers
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
    
    _env.out.print("Method: " + method_str)
    _env.out.print("Path: " + path)
    _env.out.print("Body length: " + body.size().string())
    _env.out.print("Final body: " + body.clone())
    
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

class val JsonPost
  let title: String
  let author: String
  let content: String
  let score: I64
  
  new val create(title': String, author': String, content': String, score': I64) =>
    title = title'
    author = author'
    content = content'
    score = score'

primitive JsonParser
  fun parse(json_str: String val, env: Env): Map[String, (String | Bool)]? =>
    env.out.print("=== JSON Parser Input ===")
    env.out.print("Raw input length: " + json_str.size().string())
    env.out.print("Raw input: '" + json_str + "'")
    
    let result = Map[String, (String | Bool)]
    
    try
      let content = recover val
        let tmp = String(json_str.size())
        var in_string = false
        var escaped = false
        
        for c in json_str.values() do
          match c
          | '"' if not escaped => 
            in_string = not in_string
            tmp.push(c)
          | '\\' if in_string => 
            escaped = true
            tmp.push(c)
          | ' ' | '\t' | '\n' | '\r' if not in_string => None
          else
            if escaped then
              escaped = false
            end
            tmp.push(c)
          end
        end
        tmp
      end
      
      env.out.print("Cleaned content: '" + content + "'")
      
      if (content.size() < 2) or (content(0)? != '{') or (content(content.size()-1)? != '}') then
        env.out.print("Invalid JSON format - Missing braces")
        error
      end
      
      let inner_content = recover val
        content.substring(ISize(1), ISize.from[USize](content.size() - 1))
      end
      env.out.print("Inner content: '" + inner_content + "'")
      
      let pairs = recover val inner_content.split(",") end
      env.out.print("Found " + pairs.size().string() + " pairs")
      
      for pair in pairs.values() do
        try
          env.out.print("Processing pair: '" + pair + "'")
          let pair_parts = recover val pair.split(":", 2) end
          
          let raw_key = pair_parts(0)?
          let raw_value = pair_parts(1)?
          env.out.print("Raw key: '" + raw_key + "', Raw value: '" + raw_value + "'")
          
          let key = recover val
            let tmp = String
            var started = false
            for c in raw_key.values() do
              if not started and (c == '"') then
                started = true
              elseif started and (c != '"') then
                tmp.push(c)
              end
            end
            tmp
          end
          env.out.print("Cleaned key: '" + key + "'")
          
          // Check if value is a boolean
          let trimmed_value = recover val
            String.join(raw_value.split(" ").values())
          end
          env.out.print("Trimmed value: '" + trimmed_value + "'")
          
          if trimmed_value == "true" then
            env.out.print("Adding boolean true")
            result(key) = true
          elseif trimmed_value == "false" then
            env.out.print("Adding boolean false")
            result(key) = false
          else
            // Handle as string
            let value = recover val
              let tmp = String
              var started = false
              for c in raw_value.values() do
                if not started and (c == '"') then
                  started = true
                elseif started and (c != '"') then
                  tmp.push(c)
                end
              end
              tmp
            end
            env.out.print("Adding string value: '" + value + "'")
            result(key) = value
          end
          
        else
          env.out.print("Error processing pair")
          error
        end
      end
      
      env.out.print("Successfully parsed " + result.size().string() + " pairs")
      result
      
    else
      env.out.print("JSON parsing failed")
      error
    end

actor Main
  new create(env: Env) =>
    let auth = TCPListenAuth(env.root)
    let http_server = HTTPServer(env, auth)