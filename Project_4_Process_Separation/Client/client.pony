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
      | "COMMENT_OK" =>
        _env.out.print("Comment added successfully!")
        display_menu()
      | "COMMENTS" =>
        display_comments(consume parts)
        display_menu()
      | "SUBREDDIT_OK" =>
        try
          let subreddit = parts(1)?
          _env.out.print("Successfully created subreddit: " + subreddit)
        end
        display_menu()
      | "SUBREDDIT_LIST" =>
        display_subreddits(consume parts)
        display_menu()
      else
        _env.out.print("Received unknown response: " + message)
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
    _env.out.print("1. Create Subreddit")
    _env.out.print("2. Create Post")
    _env.out.print("3. List Posts")
    _env.out.print("4. Add Comment")
    _env.out.print("5. View Comments")
    _env.out.print("6. List Subreddits")
    _env.out.print("7. Exit")
    _env.out.print("\nEnter your choice:")
    
    _env.input(recover MenuInputNotify(this) end)

  be handle_menu_choice(choice: String) =>
    match choice
    | "1" => create_subreddit()
    | "2" => create_post()
    | "3" => list_posts()
    | "4" => add_comment()
    | "5" => view_comments()
    | "6" => list_subreddits()
    | "7" => _env.exitcode(0)
    else
      _env.out.print("Invalid choice")
      display_menu()
    end

  fun ref display_posts(parts: Array[String] val) =>
    _env.out.print("\n=== Posts ===")
    try
      var post_count: USize = 0
      var i: USize = 1
      while i < parts.size() do
        if parts(i)? == "###POST###" then
          let title_str = recover val parts(i + 1)?.clone().>replace("_", " ") end
          let author = parts(i + 2)?
          let content_str = recover val parts(i + 3)?.clone().>replace("_", " ") end
          _env.out.print("\nPost #" + post_count.string())
          _env.out.print("Title: " + consume title_str)
          _env.out.print("Author: " + author)
          _env.out.print("Content: " + consume content_str)
          _env.out.print("---")
          i = i + 4
          post_count = post_count + 1
        else
          i = i + 1
        end
      end
    end

  fun ref display_comments(parts: Array[String] val) =>
    _env.out.print("\n=== Comments ===")
    try
      var i: USize = 1
      while i < parts.size() do
        let author = parts(i)?
        let content = parts(i + 1)?
        _env.out.print("\nAuthor: " + author)
        _env.out.print("Comment: " + content)
        _env.out.print("---")
        i = i + 2
      end
    end

  be prompt(message: String) =>
    _env.out.print(message)

  be get_input(notify: InputNotify iso) =>
    _env.input(LineReaderNotify(consume notify))

  fun ref create_post() =>
    prompt("Enter subreddit name:")
    get_input(recover CreatePostInputNotify(this) end)

  fun ref list_posts() =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("LIST_POSTS")
    end

  fun ref add_comment() =>
    prompt("Enter subreddit name:")
    get_input(recover CommentInputNotify(this) end)

  fun ref view_comments() =>
    prompt("Enter subreddit name:")
    get_input(recover ViewCommentsInputNotify(this) end)

  be create_post_with_data(subreddit: String val, title: String val, content: String val) =>
    match _conn
    | let conn: TCPConnection tag =>
      let encoded_title = recover val title.clone().>replace(" ", "_") end
      let encoded_content = recover val content.clone().>replace(" ", "_") end
      let msg = recover val "POST " + subreddit + " " + consume encoded_title + " " + consume encoded_content end
      conn.write(consume msg)
    end

  be add_comment_with_data(subreddit: String val, post_index: String val, content: String val) =>
    match _conn
    | let conn: TCPConnection tag =>
      let encoded_content = recover val content.clone().>replace(" ", "_") end
      let msg = recover val "COMMENT " + subreddit + " " + post_index + " " + consume encoded_content end
      conn.write(consume msg)
    end

  be view_comments_for_post(subreddit: String val, post_index: String val) =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("VIEW_COMMENTS " + subreddit + " " + post_index)
    end

  fun ref create_subreddit() =>
    prompt("Enter subreddit name:")
    get_input(recover CreateSubredditInputNotify(this) end)

  be create_subreddit_with_data(name: String val) =>
    match _conn
    | let conn: TCPConnection tag =>
      let encoded_name = recover val name.clone().>replace(" ", "_") end
      let msg = recover val "CREATE_SUBREDDIT " + consume encoded_name end
      conn.write(consume msg)
    end

  fun ref list_subreddits() =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("LIST_SUBREDDITS")
    end

  fun ref display_subreddits(parts: Array[String] val) =>
    _env.out.print("\n=== Available Subreddits ===")
    try
      var i: USize = 1
      while i < parts.size() do
        _env.out.print(i.string() + ". " + parts(i)?)
        i = i + 1
      end
      if i == 1 then
        _env.out.print("No subreddits available")
      end
    end

class CommentInputNotify is InputNotify
  let _client: RedditClient
  var _stage: USize = 0
  var _subreddit: String val = ""
  var _post_index: String val = ""
  
  new iso create(client: RedditClient) =>
    _client = client

  new iso from_state(client: RedditClient, stage': USize, subreddit': String val, post_index': String val = "") =>
    _client = client
    _stage = stage'
    _subreddit = subreddit'
    _post_index = post_index'

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    
    match _stage
    | 0 =>
      _client.prompt("Enter post index:")
      _client.get_input(recover iso CommentInputNotify.from_state(_client, 1, input) end)
    | 1 =>
      _client.prompt("Enter comment:")
      _client.get_input(recover iso CommentInputNotify.from_state(_client, 2, _subreddit, input) end)
    | 2 =>
      _client.add_comment_with_data(_subreddit, _post_index, input)
    end

  fun ref dispose() =>
    None

class ViewCommentsInputNotify is InputNotify
  let _client: RedditClient
  var _stage: USize = 0
  var _subreddit: String val = ""
  
  new iso create(client: RedditClient) =>
    _client = client

  new iso from_state(client: RedditClient, stage': USize, subreddit': String val) =>
    _client = client
    _stage = stage'
    _subreddit = subreddit'

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    
    match _stage
    | 0 =>
      _client.prompt("Enter post index:")
      _client.get_input(recover iso ViewCommentsInputNotify.from_state(_client, 1, input) end)
    | 1 =>
      _client.view_comments_for_post(_subreddit, input)
    end

  fun ref dispose() =>
    None

class MenuInputNotify is InputNotify
  let _client: RedditClient
  
  new iso create(client: RedditClient) =>
    _client = client

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    _client.handle_menu_choice(input)

  fun ref dispose() =>
    None


class CreatePostInputNotify is InputNotify
  let _client: RedditClient
  var _stage: USize = 0
  var _subreddit: String val = ""
  var _title: String val = ""
  
  new iso create(client: RedditClient) =>
    _client = client

  new iso from_state(client: RedditClient, stage': USize, subreddit': String val, title': String val = "") =>
    _client = client
    _stage = stage'
    _subreddit = subreddit'
    _title = title'

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    
    match _stage
    | 0 =>
      _client.prompt("Enter post title:")
      _client.get_input(recover iso CreatePostInputNotify.from_state(_client, 1, input) end)
    | 1 =>
      _client.prompt("Enter post content:")
      _client.get_input(recover iso CreatePostInputNotify.from_state(_client, 2, _subreddit, input) end)
    | 2 =>
      _client.create_post_with_data(_subreddit, _title, input)
    end

  fun ref dispose() =>
    None

class CreateSubredditInputNotify is InputNotify
  let _client: RedditClient
  
  new iso create(client: RedditClient) =>
    _client = client

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    _client.create_subreddit_with_data(input)

  fun ref dispose() =>
    None

class LineReaderNotify is InputNotify
  let _input_handler: InputNotify iso
  let _buffer: Array[U8]
  
  new iso create(input_handler: InputNotify iso) =>
    _input_handler = consume input_handler
    _buffer = Array[U8]
  
  fun ref apply(data: Array[U8] iso) =>
    for byte in (consume data).values() do
      if byte == 10 then // newline character
        // Send accumulated buffer to handler
        let line = recover iso Array[U8] end
        for b in _buffer.values() do
          line.push(b)
        end
        _input_handler.apply(consume line)
        _buffer.clear()
      else
        _buffer.push(byte)
      end
    end
    
  fun ref dispose() =>
    _input_handler.dispose()

  fun ref fun_stdin() =>
    None