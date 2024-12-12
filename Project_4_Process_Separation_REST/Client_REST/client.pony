use "net"
use "collections"
use "time"

primitive GET
primitive POST
primitive PUT
primitive DELETE

type Method is (GET | POST | PUT | DELETE)

actor RedditRESTClient
  let _env: Env
  let _auth: TCPConnectAuth
  let _host: String
  let _port: String
  var _conn: (TCPConnection tag | None)
  let _username: String
  
  new create(env: Env, username: String, host: String = "localhost", port: String = "8080") =>
    _env = env
    _auth = TCPConnectAuth(env.root)
    _host = host
    _port = port
    _username = username
    _conn = None
    
    _connect()
    
  fun ref _connect() =>
    _conn = TCPConnection(
      _auth,
      recover HTTPClientNotify(this, _env) end,
      _host,
      _port
    )

  be connected() =>
    _env.out.print("Connected to Reddit server")
    register_user()

  fun ref dispose() =>
    try
      (_conn as TCPConnection).dispose()
    end
    _env.exitcode(0)

  be received(response: String) =>
    _env.out.print("\nServer Response:")
    if response.contains("\"posts\":") then
      try
        let posts = response.substring(
          response.find("\"posts\":[")? + 8,
          response.find("]}")?)
        
        if posts == "" then
          _env.out.print("No posts found in this subreddit")
        else
          _env.out.print("\nPosts:")
          for post in posts.split("},").values() do
            _env.out.print("\n---")
            let clean_post = if post.substring(-1) == "}" then post else post + "}" end
            _env.out.print(clean_post)
          end
        end
      else
        _env.out.print(response)
      end
    else
      _env.out.print(response)
    end
    display_menu()

  be register_user() =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"bio\":\"A Reddit Clone user\"")
      json.append("}")
      json
    end
    
    _env.out.print("Sending registration request...")
    send_request(POST, "/users", headers, body)

  fun ref display_menu() =>
    _env.out.print("\n=== Reddit REST Client Menu ===")
    _env.out.print("1. Create Subreddit")
    _env.out.print("2. Subscribe to Subreddit")
    _env.out.print("3. Create Post")
    _env.out.print("4. Get All Posts")
    _env.out.print("5. Get Specific Post")
    _env.out.print("6. View Comments on Post")
    _env.out.print("7. Add Comment")
    _env.out.print("8. Vote on Post")
    _env.out.print("9. Vote on Comment")
    _env.out.print("10. Get Subreddit Feed (Hot)")
    _env.out.print("11. Get Subreddit Feed (New)")
    _env.out.print("12. Get Subreddit Feed (Top)")
    _env.out.print("13. Get Subreddit Feed (Controversial)")
    _env.out.print("14. Get Subscribed Subreddits Feed")
    _env.out.print("15. List Subreddits")
    _env.out.print("16. View Messages")
    _env.out.print("17. Send Message")
    _env.out.print("18. Exit")
    _env.out.print("\nEnter your choice:")
    _env.input(recover MenuInputNotify(this, _env) end)

    be handle_menu_choice(choice: String) =>
      match choice
      | "1" => create_subreddit()
      | "2" => subscribe_to_subreddit()
      | "3" => create_post()
      | "4" => get_all_posts()
      | "5" => get_specific_post()
      | "6" => view_comments()
      | "7" => add_comment()
      | "8" => vote_on_post()
      | "9" => vote_on_comment()
      | "10" => get_subreddit_feed("hot")
      | "11" => get_subreddit_feed("new")
      | "12" => get_subreddit_feed("top")
      | "13" => get_subreddit_feed("controversial")
      | "14" => get_subscribed_feed()
      | "15" => list_subreddits()
      | "16" => view_messages()
      | "17" => send_message()
      | "18" =>
        try
          (_conn as TCPConnection).dispose()
        end
        _env.exitcode(0)
        return
      else
        _env.out.print("Invalid choice")
        display_menu()
      end

  fun ref create_subreddit() =>
    prompt("Enter subreddit name:")
    get_input(recover CreateSubredditInputNotify(this, _env) end)

  fun ref subscribe_to_subreddit() =>
    prompt("Enter subreddit name:")
    get_input(recover SubscribeSubredditInputNotify(this, _env) end)

  fun ref get_all_posts() =>
    let headers = recover val Map[String, String] end
    send_request(GET, "/posts", headers, "")

  fun ref get_specific_post() =>
    prompt("Enter post ID:")
    _env.input(recover GetPostInputNotify(this, _env) end)

  fun ref create_post() =>
    prompt("Enter subreddit name:")
    get_input(recover CreatePostInputNotify(this, _env) end)

  fun ref view_comments() =>
    prompt("Enter post ID:")
    get_input(recover ViewCommentsInputNotify(this, _env) end)

  fun ref add_comment() =>
    prompt("Enter post ID:")
    get_input(recover AddCommentInputNotify(this, _env) end)

  fun ref vote_on_post() =>
    prompt("Enter post ID:")
    get_input(recover VotePostInputNotify(this, _env) end)

  fun ref vote_on_comment() =>
    prompt("Enter post ID:")
    get_input(recover VoteCommentInputNotify(this, _env) end)

  fun ref get_subreddit_feed(sort: String) =>
    prompt("Enter subreddit name:")
    get_input(recover GetFeedInputNotify(this, _env, sort) end)

  fun ref get_hot_feed() =>
    get_subreddit_feed("hot")

  fun ref get_new_feed() =>
    get_subreddit_feed("new")

  fun ref get_top_feed() =>
    get_subreddit_feed("top")
    
  fun ref get_controversial_feed() =>
    get_subreddit_feed("controversial")

  be list_subreddits() =>
    let headers = recover val Map[String, String] end
    send_request(GET, "/subreddits", headers, "")

  be get_subscribed_feed() =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map("Username") = _username
      map
    end
    send_request(GET, "/feed/subscribed", headers, "")

  be get_input(notify: InputNotify iso) =>
  _env.input(LineReaderNotify(consume notify, _env))

  be prompt(message: String) =>
    _env.out.print(message)

  be send_request(method: Method, path: String, headers: Map[String, String] val, body: String val) =>
    try
      let conn = _conn as TCPConnection tag
      let request = _build_request(method, path, headers, body)
      conn.write(consume request)
    else
      _env.out.print("Error: Not connected to server")
    end

  fun ref _build_request(method: Method, path: String, headers: Map[String, String] val, body: String): String iso^ =>
    let request = recover iso String end
    
    let method_str = match method
    | GET => "GET"
    | POST => "POST"
    | PUT => "PUT"
    | DELETE => "DELETE"
    end
    
    request.append(method_str + " " + path + " HTTP/1.1\r\n")
    request.append("Host: " + _host + ":" + _port + "\r\n")
    
    if body.size() > 0 then
      request.append("Content-Length: " + body.size().string() + "\r\n")
    end
    
    for (name, value) in headers.pairs() do
      request.append(name + ": " + value + "\r\n")
    end
    
    request.append("\r\n")
    if body.size() > 0 then
      request.append(body)
    end
    
    consume request
    

  be create_subreddit_with_data(name: String) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"name\":\"" + name + "\"")
      json.append("}")
      json
    end
    
    send_request(POST, "/subreddits", headers, body)
    
    let sub_body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\"")
      json.append("}")
      json
    end
    
    send_request(POST, "/subreddits/" + name + "/subscribe", headers, sub_body)


  be subscribe_to_subreddit_with_data(name: String) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\"")
      json.append("}")
      json
    end
    
    send_request(POST, "/subreddits/" + name + "/subscribe", headers, body)

  be create_post_with_data(subreddit: String, title: String, content: String) =>
    let sub_headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let sub_body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\"")
      json.append("}")
      json
    end
    
    send_request(POST, "/subreddits/" + subreddit + "/subscribe", sub_headers, sub_body)
    
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"title\":\"" + title + "\",")
      json.append("\"content\":\"" + content + "\"")
      json.append("}")
      json
    end
    
    send_request(POST, "/subreddits/" + subreddit + "/posts", headers, body)


  be get_post_by_id(id: String) =>
    let headers = recover val Map[String, String] end
    send_request(GET, "/posts/" + id, headers, "")

  be add_comment_with_data(post_id: String, subreddit_name: String, content: String) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end

    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"subreddit\":\"" + subreddit_name + "\",")
      json.append("\"content\":\"" + content + "\"")
      json.append("}")
      json
    end

    send_request(POST, "/posts/" + post_id + "/comments", headers, body)

  be view_post_comments(post_id: String) =>
    let headers = recover val Map[String, String] end
    send_request(GET, "/posts/" + post_id + "/comments", headers, "")

  be vote_on_post_with_data(post_id: String val, subreddit_name: String val, is_upvote: Bool val) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"subreddit\":\"" + subreddit_name + "\",")
      json.append("\"upvote\":" + if is_upvote then "true" else "false" end)
      json.append("}")
      json
    end
    
    send_request(POST, "/posts/" + post_id + "/vote", headers, body)

  be vote_on_comment_with_data(post_id: String val, subreddit_name: String val, comment_id: String val, is_upvote: Bool val) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"subreddit\":\"" + subreddit_name + "\",")
      json.append("\"upvote\":" + if is_upvote then "true" else "false" end)
      json.append("}")
      json
    end
    
    send_request(POST, "/comments/" + comment_id + "/vote", headers, body)

  be get_subreddit_feed_with_data(subreddit: String, sort: String) =>
    let headers = recover val Map[String, String] end
    send_request(GET, "/subreddits/" + subreddit + "/feed/" + sort, headers, "")

  fun ref view_messages() =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    send_request(GET, "/users/" + _username + "/messages", headers, "")

  fun ref view_thread() =>
    prompt("Enter thread ID:")
    get_input(recover ViewThreadInputNotify(this, _env) end)

  fun ref send_message() =>
    prompt("Enter recipient username:")
    get_input(recover SendMessageInputNotify(this, _env) end)

  be send_message_with_data(to_username: String, content: String, thread_id: String = "") =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"from\":\"" + _username + "\",")
      json.append("\"to\":\"" + to_username + "\",")
      json.append("\"content\":\"" + content + "\"")
      if thread_id != "" then
        json.append(",\"thread_id\":\"" + thread_id + "\"")
      end
      json.append("}")
      json
    end
    
    send_request(POST, "/messages", headers, body)



class HTTPClientNotify is TCPConnectionNotify
  let _client: RedditRESTClient
  let _env: Env
  var _buffer: String iso
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env
    _buffer = recover iso String end
  
  fun ref connected(conn: TCPConnection ref) =>
    _client.connected()
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    let data_str = String.from_array(consume data)
    
    _buffer.append(data_str)
    
    try
      let headers_end = _buffer.find("\r\n\r\n")?
      let headers = recover val _buffer.substring(0, headers_end) end
      let body_start = headers_end + 4
      let body = recover val _buffer.substring(body_start) end
      
      if body.contains("\"posts\":[") then
        try
          let posts = body.substring(
            body.find("\"posts\":[")? + 8,
            body.find("]}")?)
          
          _env.out.print("\nPosts:")
          
          let post_array = recover val posts.split("},") end
          for post in post_array.values() do
            _env.out.print("\n---")
            let clean_post = recover val 
              if post.substring(-1) == "}" then 
                post 
              else 
                post + "}" 
              end
            end
            
            try
              let title = recover val clean_post.substring(
                clean_post.find("\"title\":\"")? + 9,
                clean_post.find("\",\"author\"")?)
              end
                
              let author = recover val clean_post.substring(
                clean_post.find("\"author\":\"")? + 10,
                clean_post.find("\",\"content\"")?)
              end
                
              let content = recover val clean_post.substring(
                clean_post.find("\"content\":\"")? + 11,
                clean_post.find("\",\"score\"")?)
              end
                
              let score = recover val clean_post.substring(
                clean_post.find("\"score\":")? + 8,
                clean_post.find(",\"upvotes\"")?)
              end   
        
              _env.out.print("Title: " + title.clone())
              _env.out.print("Author: " + author.clone())
              _env.out.print("Content: " + content.clone())
              _env.out.print("Score: " + score.clone())
            end
          end
        end
      elseif body.contains("\"comments\":[") then
        try
          let comments = body.substring(
            body.find("\"comments\":[")? + 11,
            body.find("]}")?)
          
          _env.out.print("\nComments:")
          
          if comments == "" then
            _env.out.print("No comments on this post")
          else
            let comment_array = recover val comments.split("},") end
            for comment in comment_array.values() do
              _env.out.print("\n---")
              let clean_comment = recover val 
                if comment.substring(-1) == "}" then 
                  comment 
                else 
                  comment + "}" 
                end
              end
              
              try
                let author = recover val clean_comment.substring(
                  clean_comment.find("\"author\":\"")? + 10,
                  clean_comment.find("\",\"content\"")?)
                end
                  
                let content = recover val clean_comment.substring(
                  clean_comment.find("\"content\":\"")? + 11,
                  clean_comment.find("\",\"score\"")?)
                end
                  
                let score = recover val clean_comment.substring(
                  clean_comment.find("\"score\":")? + 8,
                  clean_comment.find(",\"replies\"")?)
                end
              
                _env.out.print("Author: " + author)
                _env.out.print("Content: " + content)
                _env.out.print("Score: " + score)
                
                if clean_comment.contains("\"replies\":[") then
                  try
                    let replies_str = clean_comment.substring(
                      clean_comment.find("\"replies\":[")? + 10,
                      clean_comment.find("]}")?)
                    if replies_str != "" then
                      _env.out.print("  Replies: " + consume replies_str)
                    end
                  end
                end
              end
            end
          end
        end
      else
        _env.out.print("\nServer Response: " + body)
      end

      _client.received(body)
      _buffer = recover iso String end
    end
    true
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    _env.out.print("Connection failed")

  fun ref closed(conn: TCPConnection ref) =>
    _env.out.print("Connection closed")
    _env.exitcode(0)


actor Main
  new create(env: Env) =>
    try
      let username = env.args(1)?
      let client = RedditRESTClient(env, username)
    else
      env.out.print("Usage: client <username>")
      env.exitcode(1)
    end
