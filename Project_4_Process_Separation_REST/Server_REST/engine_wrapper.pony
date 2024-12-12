use "net"
use "collections"
use "../Engine"


actor RedditEngineWrapper
  let _engine: RedditEngine ref
  let _env: Env
  
  new create(env: Env) =>
    _env = env
    _engine = RedditEngine(env)
    
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
    
  be join_subreddit_with_verification(username: String, subreddit_name: String, conn: TCPConnection tag) =>
    try
      let sub = _engine.subreddits(subreddit_name)?
      
      let username_clone = recover val username.clone().>strip() end
      
      _env.out.print("Found subreddit: " + subreddit_name)
      _env.out.print("Attempting to subscribe user: " + username_clone)
      
      _engine.join_subreddit(username_clone, subreddit_name)
      
      let updated_members = sub.get_members_clone()
      _env.out.print("Current members after join: " + ",".join(updated_members.values()))
      
      if updated_members.contains(username_clone) then
        _env.out.print("Successfully added user to subreddit members")
        let headers = recover val 
          let map = Map[String, String]
          map("Content-Type") = "application/json"
          map
        end
        let response = HTTPResponse(200, headers, 
          "{\"status\":\"success\",\"message\":\"Subscribed to subreddit\"}\n")
        conn.write(response.string())
      else
        _env.out.print("Failed to add user to subreddit members")
        let headers = recover val Map[String, String] end
        let response = HTTPResponse(500, headers, 
          "{\"error\":\"Failed to verify subscription\"}\n")
        conn.write(response.string())
      end
    else
      _env.out.print("Error: Subreddit not found - " + subreddit_name)
      let headers = recover val Map[String, String] end
      let response = HTTPResponse(404, headers, 
        "{\"error\":\"Subreddit not found\"}\n")
      conn.write(response.string())
    end


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

  be get_post_with_comments(post_id: USize, conn: TCPConnection tag) =>
    try
      let json_headers = recover val 
        let map = Map[String, String]
        map("Content-Type") = "application/json"
        map
      end

      let response = recover iso String end
      response.append("{\"comments\":[")
      
      (let post, let subreddit_name) = _engine.get_post_with_comments(post_id)?
      let comments = post.get_comments()
      
      var first = true
      for comment in comments.values() do
        if not first then response.append(",") end
        response.append("{")
        response.append("\"author\":\"" + comment.get_author() + "\",")
        response.append("\"content\":\"" + comment.get_content() + "\",")
        response.append("\"score\":" + comment.get_score().string() + ",")
        response.append("\"replies\":[")
        
        // Add replies
        var first_reply = true
        for reply in comment.get_replies().values() do
          if not first_reply then response.append(",") end
          response.append("{")
          response.append("\"author\":\"" + reply.get_author() + "\",")
          response.append("\"content\":\"" + reply.get_content() + "\",")
          response.append("\"score\":" + reply.get_score().string())
          response.append("}")
          first_reply = false
        end
        
        response.append("]")
        response.append("}")
        first = false
      end
      
      response.append("]}")
      
      let http_response = HTTPResponse(200, json_headers, consume response)
      conn.write(http_response.string())
    else
      let error_headers = recover val Map[String, String] end
      let error_response = HTTPResponse(404, error_headers, "{\"error\":\"Post not found\"}\n")
      conn.write(error_response.string())
    end

  be vote_on_comment(username: String, subreddit: String, post_id: USize, 
    comment_id: USize, is_upvote: Bool) =>
    _engine.vote_on_comment(username, subreddit, post_id, comment_id, is_upvote)
    _env.out.print("Processed vote on comment " + comment_id.string())

  be get_post(post_id: USize, conn: TCPConnection tag) =>

    for (subreddit_name, subreddit) in _engine.subreddits.pairs() do
      try
        let post = _engine.get_post(post_id, subreddit_name)?
        let response = JsonBuilder.post_with_comments(post)
        conn.write(response)
        return
      end
    end

    let headers = recover val Map[String, String] end
    let error_response = HTTPResponse(404, headers, "{\"error\":\"Post not found\"}\n")
    conn.write(error_response.string())

  be get_popular_feed(conn: TCPConnection tag) =>
    let feed = _engine.get_popular_feed()
    let response = JsonBuilder.feed_to_json(feed)
    conn.write(response)

  be get_user_subscribed_feed(username: String, conn: TCPConnection tag) =>
    _env.out.print("\n=== Generating Subscribed Feed ===")
    
    let username_val = recover val username.clone().>strip() end
    _env.out.print("User: " + username_val)
    
    let feed = _engine.get_user_feed(username_val)
    _env.out.print("Feed generated with " + feed.posts.size().string() + " posts")
    
    let response = JsonBuilder.feed_to_json(feed)
    _env.out.print("Generated JSON response: " + response)
    
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let http_response = HTTPResponse(200, headers, response)
    conn.write(http_response.string())
      
  be get_sorted_subreddit_feed(subreddit: String, sort_type: U8, conn: TCPConnection tag) =>
    try
      _env.out.print("Getting feed for subreddit: " + subreddit)
      let feed = _engine.get_subreddit_feed(subreddit, sort_type)?
      _env.out.print("Got feed with " + feed.posts.size().string() + " posts")
      
      let response_body = JsonBuilder.feed_to_json(feed)
      
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

  be get_user_messages(username: String, conn: TCPConnection tag) =>
    try
      let user = _engine.users(username)?
      user.get_messages_for_server(_env, conn)
    else
      let headers = recover val Map[String, String] end
      let error_response = HTTPResponse(404, headers, "{\"error\":\"User not found\"}\n")
      conn.write(error_response.string())
    end

  be get_message_thread(username: String, thread_id: String, conn: TCPConnection tag) =>
    try
      let user = _engine.users(username)?
      user.get_message_thread_for_server(_env, thread_id, conn)
    else
      let headers = recover val Map[String, String] end
      let error_response = HTTPResponse(404, headers, "{\"error\":\"Thread or user not found\"}\n")
      conn.write(error_response.string())
    end

  be send_message(from_username: String, to_username: String, content: String, 
    thread_id: String, conn: TCPConnection tag) =>
    _engine.send_direct_message(from_username, to_username, content, thread_id)
    
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let response = HTTPResponse(201, headers, 
      "{\"status\":\"success\",\"message\":\"Message sent successfully\"}\n")
    conn.write(response.string())

