use "net"

actor RedditClient is ClientNotify
  let _env: Env
  var _conn: (TCPConnection tag | None)
  let _username: String
  
  new create(env: Env, username: String) =>
    _env = env
    _username = username
    _conn = None
    

      let auth = TCPConnectAuth(env.root)
      let conn = TCPConnection(
        auth,
        recover ClientConnectionNotify(this, env) end,
        "localhost",
        "8989"
      )
      _conn = conn

    
  be connected() =>
    _env.out.print("Connected to Reddit server")
    try_login()
    
  be received(data: Array[U8] val) =>
    try
      let message = String.from_array(data)
      _env.out.print("Received: " + message)
      
      let parts = recover val String.from_array(data).split(" ") end
      let response = parts(0)?
      match response
      | "LOGIN_OK" => 
        _env.out.print("Successfully logged in!")
        display_menu()
      | "POST_OK" =>
        _env.out.print("Post created successfully!")
        display_menu()
      | "POST_LIST" =>
        display_posts(consume parts)
        display_menu()
      end
    end
    
  be closed() =>
    _env.out.print("Disconnected from Reddit server")
    _conn = None
    
  be connect_failed() =>
    _env.out.print("Failed to connect to Reddit server")
    _conn = None

  fun ref try_login() =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("LOGIN " + _username.clone())
      _env.out.print("Sent login request for user: " + _username)
    end

  fun ref display_menu() =>
    _env.out.print("\n=== Reddit Menu ===")
    _env.out.print("1. Create Post")
    _env.out.print("2. List Posts")
    _env.out.print("3. Exit")
    _env.out.print("\nEnter your choice:")
    
    _env.input(recover MenuInputNotify(this) end)

  fun ref display_posts(parts: Array[String] val) =>
    _env.out.print("\n=== Posts ===")
    try
      var i: USize = 1
      while i < parts.size() do
        let title = parts(i)?
        let author = parts(i + 1)?
        let content = parts(i + 2)?
        _env.out.print("\nPost #" + ((i-1)/3).string())
        _env.out.print("Title: " + title)
        _env.out.print("Author: " + author)
        _env.out.print("Content: " + content)
        _env.out.print("---")
        i = i + 3
      end
    end

  be handle_menu_choice(input: String) =>
    match input
    | "1" => create_post()
    | "2" => list_posts()
    | "3" => _env.exitcode(0)
    else
      _env.out.print("Invalid choice")
      display_menu()
    end

  be prompt(message: String) =>
    _env.out.print(message)

  be get_input(notify: InputNotify iso) =>
    _env.input(consume notify)

  fun ref create_post() =>
    prompt("Enter subreddit name:")
    get_input(recover CreatePostInputNotify(this) end)

  fun ref list_posts() =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("LIST_POSTS")
    end

  be create_post_with_data(subreddit: String, title: String, content: String) =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("POST " + subreddit + " " + title + " " + content)
    end

class MenuInputNotify is InputNotify
  let _client: RedditClient
  
  new iso create(client: RedditClient) =>
    _client = client

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data)
    _client.handle_menu_choice(input)

  fun ref dispose() =>
    None

class CreatePostInputNotify is InputNotify
  let _client: RedditClient
  var _stage: USize = 0
  var _subreddit: String = ""
  var _title: String = ""
  
  new iso create(client: RedditClient) =>
    _client = client

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data)
    
    match _stage
    | 0 =>
      _subreddit = input.clone()
      _stage = 1
      _client.prompt("Enter post title:")
      _client.get_input(recover CreatePostInputNotify.create_next(
        _client, 1, _subreddit.clone(), "") end)
    | 1 =>
      _title = input.clone()
      _stage = 2
      _client.prompt("Enter post content:")
      _client.get_input(recover CreatePostInputNotify.create_next(
        _client, 2, _subreddit.clone(), _title.clone()) end)
    | 2 =>
      _client.create_post_with_data(_subreddit, _title, input.clone())
    end

  new iso create_next(
    client: RedditClient tag,
    stage': USize,
    subreddit': String val,
    title': String val) 
  =>
    _client = client
    _stage = stage'
    _subreddit = subreddit'
    _title = title'

  fun ref dispose() =>
    None