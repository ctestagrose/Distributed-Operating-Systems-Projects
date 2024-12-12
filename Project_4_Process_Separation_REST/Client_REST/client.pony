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
    
    // Connect immediately upon creation
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

  be received(response: String) =>
    _env.out.print("\nServer Response:")
    if response.contains("\"posts\":") then
      try
        // Pretty print the posts
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
    // Always show menu after any response
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
  // Add a newline for spacing
  _env.out.print("\n=== Reddit REST Client Menu ===")
  _env.out.print("1. Create Subreddit")
  _env.out.print("2. Subscribe to Subreddit")
  _env.out.print("3. Create Post")
  _env.out.print("4. Get All Posts")
  _env.out.print("5. Get Specific Post")
  _env.out.print("6. Add Comment")
  _env.out.print("7. Vote on Post")
  _env.out.print("8. Vote on Comment")
  _env.out.print("9. Get Subreddit Feed (Hot)")
  _env.out.print("10. Get Subreddit Feed (New)")
  _env.out.print("11. Get Subreddit Feed (Top)")
  _env.out.print("12. Get Subreddit Feed (Controversial)")
  _env.out.print("13. Get Subscribed Subreddits Feed")
  _env.out.print("14. List Subreddits")
  _env.out.print("15. Exit")
  _env.out.print("\nEnter your choice:")
  _env.input(recover MenuInputNotify(this, _env) end)

  be handle_menu_choice(choice: String) =>
    match choice
    | "1" => create_subreddit()
    | "2" => subscribe_to_subreddit()
    | "3" => create_post()
    | "4" => get_all_posts()
    | "5" => get_specific_post()
    | "6" => add_comment()
    | "7" => vote_on_post()
    | "8" => vote_on_comment()
    | "9" => get_subreddit_feed("hot")
    | "10" => get_subreddit_feed("new")
    | "11" => get_subreddit_feed("top")
    | "12" => get_subreddit_feed("controversial")
    | "13" => get_subscribed_feed()
    | "14" => list_subreddits()
    | "15" => _env.exitcode(0)
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
      map("Username") = _username  // Add username to headers for server to filter feed
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
    
    // Auto-subscribe after creation
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
    // First ensure we're subscribed to the subreddit
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
    
    // Subscribe first
    send_request(POST, "/subreddits/" + subreddit + "/subscribe", sub_headers, sub_body)
    
    // Then create the post
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

// Input handler classes for menu options
class MenuInputNotify is InputNotify
  let _client: RedditRESTClient
  let _buffer: String ref
  let _env: Env

  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _buffer = String
    _env = env

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data)
    for c in input.values() do
      if (c.u8() == 8) or (c.u8() == 127) then
        if _buffer.size() > 0 then
          _buffer.truncate(_buffer.size() - 1)
          _env.out.write(recover val [8; 32; 8] end)
        end
      else
        if (c == 10) or (c == 13) then
          let choice = _buffer.clone().>trim()
          if choice != "" then
            _env.out.write(recover val [c.u8()] end)
            _client.handle_menu_choice(choice)
          end
          _buffer.clear()
        else
          _env.out.write(recover val [c.u8()] end)
          _buffer.push(c)
        end
      end
    end

  fun ref dispose() =>
    None
class CreateSubredditInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"name\":\"" + input + "\"")
      json.append("}")
      json
    end
    
    _client.send_request(POST, "/subreddits", headers, body)

  fun ref dispose() =>
    None

class SubscribeSubredditInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    _client.subscribe_to_subreddit_with_data(input)
  
  fun ref dispose() =>
    None

class CreatePostInputNotify is InputNotify
  let _client: RedditRESTClient tag  // Make sure this is explicitly tagged as tag
  let _env: Env
  var _stage: USize
  var _subreddit: String
  var _title: String
  
  new iso create(client: RedditRESTClient tag, env: Env, stage: USize = 0, 
    subreddit: String = "", title: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _subreddit = subreddit
    _title = title
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _subreddit = input
      _env.out.print("Enter post title:")
      _client.get_input(recover CreatePostInputNotify(_client, _env, 1, _subreddit) end)
    | 1 =>
      _title = input
      _env.out.print("Enter post content:")
      _client.get_input(recover CreatePostInputNotify(_client, _env, 2, _subreddit, _title) end)
    | 2 =>
      _client.create_post_with_data(_subreddit, _title, input)
    end
  
  fun ref dispose() =>
    None


class GetPostInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    _client.get_post_by_id(input)
  
  fun ref dispose() =>
    None

class AddCommentInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  var _stage: USize
  var _post_id: String
  var _subreddit_name: String
  
  new iso create(client: RedditRESTClient, env: Env, stage: USize = 0, post_id: String = "", subreddit_name: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _post_id = post_id
    _subreddit_name = subreddit_name
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _post_id = input
      _env.out.print("Enter subreddit name:")
      _client.get_input(recover AddCommentInputNotify(_client, _env, 1, _post_id) end)
    | 1 =>
      _subreddit_name = input
      _env.out.print("Enter comment content:")
      _client.get_input(recover AddCommentInputNotify(_client, _env, 2, _post_id, _subreddit_name) end)
    | 2 =>
      _client.add_comment_with_data(_post_id, _subreddit_name, input)
    end
  
  fun ref dispose() =>
    None

class VotePostInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  var _stage: USize
  var _post_id: String
  var _subreddit_name: String

  new iso create(client: RedditRESTClient, env: Env, stage: USize = 0, post_id: String = "", subreddit_name: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _post_id = post_id
    _subreddit_name = subreddit_name

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _post_id = input
      _env.out.print("Enter subreddit name:")
      _client.get_input(recover VotePostInputNotify(_client, _env, 1, _post_id, "") end)
    | 1 =>
      _subreddit_name = input
      _env.out.print("Enter vote type (up/down):")
      _client.get_input(recover VotePostInputNotify(_client, _env, 2, _post_id, _subreddit_name) end)
    | 2 =>
      let is_upvote = input.lower() == "up"
      _client.vote_on_post_with_data(_post_id, _subreddit_name, is_upvote)
    end

  fun ref dispose() =>
    None

class VoteCommentInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  var _stage: USize
  var _post_id: String
  var _comment_id: String
  var _subreddit_name: String

  new iso create(client: RedditRESTClient, env: Env, stage: USize = 0, post_id: String = "", comment_id: String = "", subreddit_name: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _post_id = post_id
    _comment_id = comment_id
    _subreddit_name = subreddit_name

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _post_id = input
      _env.out.print("Enter subreddit name:")
      _client.get_input(recover VoteCommentInputNotify(_client, _env, 1, _post_id, "", "") end)
    | 1 =>
      _subreddit_name = input
      _env.out.print("Enter comment ID:")
      _client.get_input(recover VoteCommentInputNotify(_client, _env, 2, _post_id, "", _subreddit_name) end)
    | 2 =>
      _comment_id = input
      _env.out.print("Enter vote type (up/down):")
      _client.get_input(recover VoteCommentInputNotify(_client, _env, 3, _post_id, _comment_id, _subreddit_name) end)
    | 3 =>
      let is_upvote = input.lower() == "up"
      _client.vote_on_comment_with_data(_post_id, _subreddit_name, _comment_id, is_upvote)
    end

  fun ref dispose() =>
    None

class GetFeedInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  let _sort: String
  
  new iso create(client: RedditRESTClient, env: Env, sort: String) =>
    _client = client
    _env = env
    _sort = sort
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    _client.get_subreddit_feed_with_data(input, _sort)
  
  fun ref dispose() =>
    None

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
            // Extract and format individual post fields
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
            
            // Print formatted post
            _env.out.print("Title: " + title.clone())
            _env.out.print("Author: " + author.clone())
            _env.out.print("Content: " + content.clone())
            _env.out.print("Score: " + score.clone())
          end
        end
      end
    else
      // For other responses, just print the body
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

primitive JsonBuilder
  fun user_to_json(username: String, bio: String = ""): String =>
    "{\"username\":\"" + username + "\",\"bio\":\"" + bio + "\"}"
    
  fun post_to_json(username: String, title: String, content: String): String =>
    "{\"username\":\"" + username + "\",\"title\":\"" + title + 
    "\",\"content\":\"" + content + "\"}"
    
  fun comment_to_json(username: String, content: String): String =>
    "{\"username\":\"" + username + "\",\"content\":\"" + content + "\"}"
    
  fun vote_to_json(username: String, is_upvote: Bool): String =>
    "{\"username\":\"" + username + "\",\"upvote\":" + 
    if is_upvote then "true" else "false" end + "}"

class LineReaderNotify is InputNotify
  let _input_handler: InputNotify iso
  let _buffer: Array[U8]
  let _env: Env

  new iso create(input_handler: InputNotify iso, env: Env) =>
    _input_handler = consume input_handler
    _buffer = Array[U8]
    _env = env

  fun ref apply(data: Array[U8] iso) =>
    for byte in (consume data).values() do
      if (byte == 8) or (byte == 127) then  // Backspace
        if _buffer.size() > 0 then
          try
            _buffer.pop()?
            _env.out.write(recover val [8; 32; 8] end)
          end
        end
      elseif byte == 10 then  // Enter/Return
        _env.out.write([10])
        let line = recover iso Array[U8] end
        for b in _buffer.values() do
          line.push(b)
        end
        _input_handler.apply(consume line)
        _buffer.clear()
      else
        _buffer.push(byte)
        _env.out.write(recover val [byte] end)
      end
    end

  fun ref dispose() =>
    _input_handler.dispose()

actor Main
  new create(env: Env) =>
    try
      let username = env.args(1)?
      let client = RedditRESTClient(env, username)
    else
      env.out.print("Usage: client <username>")
      env.exitcode(1)
    end
