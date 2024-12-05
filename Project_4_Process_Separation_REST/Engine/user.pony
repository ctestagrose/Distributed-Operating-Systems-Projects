use "collections"
use "random"
use "time"
use "net"
use "../Server_REST"

class UserProfile
  let username: String
  let bio: String
  let join_date: I64
  var posts: Array[PostRef] ref
  var comments: Array[CommentRef] ref
  var subreddit_karma: Map[String, SubredditKarma] ref
  let achievements: Set[String] ref
  
  new create(username': String, bio': String = "") =>
    username = username'
    bio = bio'
    join_date = Time.now()._1
    posts = Array[PostRef]
    comments = Array[CommentRef]
    subreddit_karma = Map[String, SubredditKarma]
    achievements = Set[String]

  fun ref get_subreddit_karma(): Map[String, SubredditKarma] ref =>
    subreddit_karma

  fun ref get_achievements(): Set[String] ref =>
    achievements

class PostRef
  let title: String
  let subreddit: String
  let created_at: I64
  let post_id: USize
  
  new create(title': String, subreddit': String, post_id': USize) =>
    title = title'
    subreddit = subreddit'
    created_at = Time.now()._1
    post_id = post_id'

class CommentRef
  let content: String
  let subreddit: String
  let post_id: USize
  let created_at: I64
  
  new create(content': String, subreddit': String, post_id': USize) =>
    content = content'
    subreddit = subreddit'
    post_id = post_id'
    created_at = Time.now()._1

class SubredditKarma
  var post_karma: I64
  var comment_karma: I64
  
  new create() =>
    post_karma = 0
    comment_karma = 0
    
  fun ref add_post_karma(amount: I64) =>
    post_karma = post_karma + amount
    
  fun ref add_comment_karma(amount: I64) =>
    comment_karma = comment_karma + amount
    
  fun get_total(): I64 =>
    post_karma + comment_karma

actor User
  let _profile: UserProfile
  let _env: Env
  var _post_karma: I64
  var _comment_karma: I64
  let _inbox: Array[Message] ref
  let _sent: Array[Message] ref
  let _message_threads: Map[String, Array[Message] ref] ref
  
  new create(env: Env, username: String, bio: String = "") =>
    _env = env
    _profile = UserProfile(username, bio)
    _post_karma = 0
    _comment_karma = 0
    _inbox = Array[Message]
    _sent = Array[Message]
    _message_threads = Map[String, Array[Message] ref]

  be print_name(env: Env) =>
    env.out.print(_profile.username)

  fun get_username(): String =>
    _profile.username

  fun get_bio(): String =>
    _profile.bio
    
  fun get_join_date(): I64 =>
    _profile.join_date

  fun get_post_karma(): I64 =>
    _post_karma

  fun get_comment_karma(): I64 =>
    _comment_karma

  be add_post(title: String, subreddit: String, post_id: USize) =>
    let post_ref = PostRef(title, subreddit, post_id)
    _profile.posts.push(post_ref)

  be add_post_karma(amount: I64, subreddit: String) =>
    _post_karma = _post_karma + amount
    try
      if not _profile.subreddit_karma.contains(subreddit) then
        _profile.subreddit_karma(subreddit) = SubredditKarma
      end
      _profile.subreddit_karma(subreddit)?.add_post_karma(amount)
    end
    check_achievements()

  be add_comment(content: String, subreddit: String, post_id: USize) =>
    let comment_ref = CommentRef(content, subreddit, post_id)
    _profile.comments.push(comment_ref)

  be add_comment_karma(amount: I64, subreddit: String) =>
    _comment_karma = _comment_karma + amount
    try
      if not _profile.subreddit_karma.contains(subreddit) then
        _profile.subreddit_karma(subreddit) = SubredditKarma
      end
      _profile.subreddit_karma(subreddit)?.add_comment_karma(amount)
    end
    check_achievements()

  fun get_total_karma(): I64 =>
    _post_karma + _comment_karma

  be reply_to_message(thread_id: String, content: String) =>
    try
      let thread = _message_threads(thread_id)?
      if thread.size() > 0 then
        let original = thread(0)?
        let recipient = original.sender
        let message_id = _generate_message_id()
        let reply = Message(_profile.username, recipient, content, message_id, thread_id)
        thread.push(reply)
        _sent.push(reply)
      end
    end

  be get_messages(env: Env) =>
    env.out.print("\nInbox for " + _profile.username + ":")
    for message in _inbox.values() do
      env.out.print("From: " + message.sender + 
        " | Timestamp: " + message.timestamp.string() +
        "\nContent: " + message.content)
    end

  be get_message_thread(env: Env, thread_id: String) =>
    try
      let thread = _message_threads(thread_id)?
      env.out.print("\nMessage Thread " + thread_id + ":")
      for message in thread.values() do
        env.out.print("From: " + message.sender + 
          " | To: " + message.recipient +
          " | Timestamp: " + message.timestamp.string() +
          "\nContent: " + message.content)
      end
    end
  
  be get_messages_for_client(conn: TCPConnection tag) =>
    let response = recover iso String end
    response.append("MESSAGES")
    
    for message in _inbox.values() do
      response.append(" ###MSG###")
      response.append(" " + message.sender)
      response.append(" " + message.content.clone().>replace(" ", "_"))
      response.append(" " + message.timestamp.string())
      response.append(" " + message.message_id)
    end
    
    conn.write(consume response)

  be send_message(recipient: String val, content: String val, thread_id: String val = "") =>
    let message_id: String val = _generate_message_id()
    let actual_thread_id: String val = if thread_id == "" then message_id else thread_id end
    
    let message = Message(_profile.username, recipient, content, message_id, actual_thread_id)
    _sent.push(message)
    
    try
      if not _message_threads.contains(actual_thread_id) then
        _message_threads(actual_thread_id) = Array[Message]
      end
      _message_threads(actual_thread_id)?.push(message)
    end

  be receive_message(message: Message val) =>
    _inbox.push(message)
    try
      if not _message_threads.contains(message.thread_id) then
        _message_threads(message.thread_id) = Array[Message]
      end
      _message_threads(message.thread_id)?.push(message)
    end

  fun _generate_message_id(): String =>
    Time.now()._1.string() + "_" + _profile.username

  fun ref get_subreddit_karma(): Map[String, SubredditKarma] ref =>
    _profile.get_subreddit_karma()

  fun ref get_achievements(): Set[String] ref =>
    _profile.get_achievements()


  be get_profile_data(conn: TCPConnection tag, server: HTTPServer tag) =>
    let karma_str = recover iso String end
    for (subreddit, karma) in _profile.get_subreddit_karma().pairs() do
      karma_str.append(subreddit + ":" + karma.get_total().string() + " ")
    end
    
    let achievement_str = recover iso String end
    for achievement in _profile.get_achievements().values() do
      achievement_str.append(achievement + " ")
    end
    
    server.receive_profile_data(
      _profile.username,
      _profile.bio,
      _profile.join_date,
      _post_karma,
      _comment_karma,
      get_total_karma(),
      consume karma_str,
      consume achievement_str,
      conn
    )

  fun ref check_achievements() =>
    if _post_karma > 1000 then
      _profile.achievements.set("Popular Poster")
    end
    if _comment_karma > 500 then
      _profile.achievements.set("Active Commenter")
    end
    if _profile.posts.size() >= 10 then
      _profile.achievements.set("Prolific Poster")
    end
    if _profile.comments.size() >= 50 then
      _profile.achievements.set("Discussion Master")
    end
    if (_post_karma + _comment_karma) > 5000 then
      _profile.achievements.set("Karma Elite")
    end
    if _profile.subreddit_karma.size() > 5 then
      _profile.achievements.set("Community Explorer")
    end

  be print_profile(env: Env) =>
    env.out.print("\n=== User Profile: " + _profile.username + " ===")
    env.out.print("Bio: " + _profile.bio)
    env.out.print("Join Date: " + _profile.join_date.string())
    env.out.print("Total Karma: " + get_total_karma().string())
    env.out.print("  Post Karma: " + _post_karma.string())
    env.out.print("  Comment Karma: " + _comment_karma.string())
    
    env.out.print("\nKarma by Subreddit:")
    for (subreddit, karma) in _profile.subreddit_karma.pairs() do
      env.out.print("  " + subreddit + ": " + karma.get_total().string() + 
        " (Posts: " + karma.post_karma.string() + ", Comments: " + karma.comment_karma.string() + ")")
    end
    
    env.out.print("\nRecent Posts:")
    for post in _profile.posts.values() do
      env.out.print("  " + post.title + " in r/" + post.subreddit)
    end
    
    env.out.print("\nRecent Comments:")
    for comment in _profile.comments.values() do
      env.out.print("  \"" + comment.content + "\" in r/" + comment.subreddit)
    end
    
    env.out.print("\nAchievements:")
    for achievement in _profile.achievements.values() do
      env.out.print("  " + achievement)
    end