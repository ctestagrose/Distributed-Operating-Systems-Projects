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
      | "JOIN_OK" =>
        try
          let subreddit = parts(1)?
          _env.out.print("Successfully joined subreddit: " + subreddit)
        end
        display_menu()
      | "LEAVE_OK" =>
        try
          let subreddit = parts(1)?
          _env.out.print("Successfully left subreddit: " + subreddit)
        end
        display_menu()
      | "MESSAGES" =>
        display_messages(consume parts)
        display_menu()
      | "MESSAGE_SENT" =>
        _env.out.print("Message sent successfully!")
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
    _env.out.print("3. List All Posts")
    _env.out.print("4. Add Comment")
    _env.out.print("5. View Comments")
    _env.out.print("6. List All Subreddits")
    _env.out.print("7. List My Subreddits")
    _env.out.print("8. View My Feed")
    _env.out.print("9. Join Subreddit")
    _env.out.print("10. Leave Subreddit")
    _env.out.print("11. View Messages")
    _env.out.print("12. Send Message")
    _env.out.print("13. Reply to Message")
    _env.out.print("14. Exit")
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
    | "7" => list_joined_subreddits()
    | "8" => list_feed()
    | "9" => join_subreddit()
    | "10" => leave_subreddit()
    | "11" => view_messages()
    | "12" => send_message()
    | "13" => reply_to_message()
    | "14" => _env.exitcode(0)
    else
      _env.out.print("Invalid choice")
      display_menu()
    end

  fun ref send_message() =>
    prompt("Enter recipient username:")
    get_input(recover SendMessageInputNotify(this) end)

  fun ref reply_to_message() =>
    prompt("Enter message ID to reply to:")
    get_input(recover ReplyMessageInputNotify(this) end)

  fun ref display_messages(parts: Array[String] val) =>
    _env.out.print("\n=== Your Messages ===")
    try
      var i: USize = 1
      while i < parts.size() do
        if parts(i)? == "###MSG###" then
          let sender = parts(i + 1)?
          let content = recover val parts(i + 2)?.clone().>replace("_", " ") end
          let timestamp = parts(i + 3)?
          _env.out.print("\nFrom: " + sender)
          _env.out.print("Content: " + content)
          _env.out.print("Sent at: " + timestamp)
          _env.out.print("---")
          i = i + 4
        else
          i = i + 1
        end
      end
      if i == 1 then
        _env.out.print("No messages.")
      end
    end

  be send_message_with_data(recipient: String val, content: String val) =>
    match _conn
    | let conn: TCPConnection tag =>
      let encoded_content = recover val content.clone().>replace(" ", "_") end
      conn.write("SEND_MESSAGE " + recipient + " " + consume encoded_content)
    end

  be reply_message_with_data(message_id: String val, content: String val) =>
    match _conn
    | let conn: TCPConnection tag =>
      let encoded_content = recover val content.clone().>replace(" ", "_") end
      conn.write("REPLY_MESSAGE " + message_id + " " + consume encoded_content)
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
        if parts(i)? == "###COMMENT###" then
          let author = parts(i + 1)?
          let content_str = recover val parts(i + 2)?.clone().>replace("_", " ") end
          _env.out.print("\nAuthor: " + author)
          _env.out.print("Content: " + content_str)
          _env.out.print("---")
          i = i + 3
        else
          i = i + 1
        end
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

  fun ref view_messages() =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("VIEW_MESSAGES")
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

  fun ref join_subreddit() =>
  prompt("Enter subreddit name to join:")
  get_input(recover JoinSubredditInputNotify(this) end)

  fun ref leave_subreddit() =>
    prompt("Enter subreddit name to leave:")
    get_input(recover LeaveSubredditInputNotify(this) end)

  be join_subreddit_with_data(subreddit_name: String val) =>
  match _conn
  | let conn: TCPConnection tag =>
    conn.write("JOIN_SUBREDDIT " + subreddit_name)
  end

  be leave_subreddit_with_data(subreddit_name: String val) =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("LEAVE_SUBREDDIT " + subreddit_name)
    end

  fun ref list_joined_subreddits() =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("LIST_JOINED_SUBREDDITS")
    end

  fun ref list_feed() =>
    match _conn
    | let conn: TCPConnection tag =>
      conn.write("LIST_FEED")
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

class JoinSubredditInputNotify is InputNotify
  let _client: RedditClient
  
  new iso create(client: RedditClient) =>
    _client = client

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    _client.join_subreddit_with_data(input)

  fun ref dispose() =>
    None

class LeaveSubredditInputNotify is InputNotify
  let _client: RedditClient
  
  new iso create(client: RedditClient) =>
    _client = client

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    _client.leave_subreddit_with_data(input)

  fun ref dispose() =>
    None

class SendMessageInputNotify is InputNotify
  let _client: RedditClient
  var _stage: USize = 0
  var _recipient: String val = ""
  
  new iso create(client: RedditClient) =>
    _client = client

  new iso from_state(client: RedditClient, stage': USize, recipient': String val = "") =>
    _client = client
    _stage = stage'
    _recipient = recipient'

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    
    match _stage
    | 0 =>
      _client.prompt("Enter message content:")
      _client.get_input(recover iso SendMessageInputNotify.from_state(_client, 1, input) end)
    | 1 =>
      _client.send_message_with_data(_recipient, input)
    end

  fun ref dispose() =>
    None

class ReplyMessageInputNotify is InputNotify
  let _client: RedditClient
  var _stage: USize = 0
  var _message_id: String val = ""
  
  new iso create(client: RedditClient) =>
    _client = client

  new iso from_state(client: RedditClient, stage': USize, message_id': String val = "") =>
    _client = client
    _stage = stage'
    _message_id = message_id'

  fun ref apply(data: Array[U8] iso) =>
    let input = recover val String.from_array(consume data).>trim() end
    
    match _stage
    | 0 =>
      _client.prompt("Enter reply content:")
      _client.get_input(recover iso ReplyMessageInputNotify.from_state(_client, 1, input) end)
    | 1 =>
      _client.reply_message_with_data(_message_id, input)
    end

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

class MenuInputNotify is InputNotify
  let _client: RedditClient
  let _buffer: String ref
  
  new iso create(client: RedditClient) =>
    _client = client
    _buffer = String

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data)
    for c in input.values() do
      if (c == 10) or (c == 13) then // Newline or carriage return
        let choice = _buffer.clone().>trim()
        if choice != "" then
          _client.handle_menu_choice(choice)
        end
        _buffer.clear()
      else
        _buffer.push(c)
      end
    end


  fun ref dispose() =>
    None
