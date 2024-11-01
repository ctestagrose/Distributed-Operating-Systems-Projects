use "collections"
use "random"
use "time"

class RedditEngine
  var users: Map[String, User] ref
  var subreddits: Map[String, Subreddit] ref
  let _random: Random
  let _env: Env


  new create(env: Env) =>
    _env = env
    users = Map[String, User]
    subreddits = Map[String, Subreddit]
    _random = Rand(Time.now()._2.u64())


  fun ref run(num_users: U64) =>
    _env.out.print("Welcome to the Reddit Engine Simulator!")
    
    for i in Range[USize](0, num_users.usize()) do
      let random_name = generate_random_string()
      register_user(random_name)
      _env.out.print("Registered new user: " + random_name)
    end

    _env.out.print("\nAll registered users: " + ",".join(users.keys()))

    try
      // Pick first user as subreddit creator
      let creator = users.keys().next()?
      let subreddit_name = "programming"
      
      _env.out.print("\n\nTesting subreddit creation and joining:")
      _env.out.print("User " + creator + " is creating subreddit: " + subreddit_name)
      
      create_subreddit(subreddit_name)
      join_subreddit(creator, subreddit_name)

      create_post(creator, subreddit_name, "First Post!", "Hello World!")

      var leaving_user: String = ""
      for username in users.keys() do
        if username != creator then
          join_subreddit(username, subreddit_name)
          _env.out.print("User " + username + " joined " + subreddit_name)
          // Store one username to test leaving later
          leaving_user = username
        end
      end

      print_subreddit_posts(subreddit_name)

      print_subreddit_stats(subreddit_name)

      if leaving_user != "" then
        _env.out.print("\nTesting leave functionality:")
        _env.out.print("User " + leaving_user + " is leaving " + subreddit_name)
        leave_subreddit(leaving_user, subreddit_name)
        
        // Print updated stats after user leaves
        print_subreddit_stats(subreddit_name)
      end
      
    end

  fun ref print_subreddit_stats(subreddit_name: String) =>
    try
      let sub = subreddits(subreddit_name)?
      _env.out.print("\nSubreddit " + subreddit_name + " stats:")
      _env.out.print("Member count: " + sub.get_member_count().string())
      _env.out.print("Members: " + ",".join(sub.get_members_clone().values()))
    end


  fun ref print_subreddit_posts(subreddit_name: String) =>
    try
      let sub = subreddits(subreddit_name)?
      let posts = sub.get_posts()
      _env.out.print("\nPosts in " + subreddit_name + ":")
      for post in posts.values() do
        _env.out.print("\nTitle: " + post.title)
        _env.out.print("Author: " + post.author)
        _env.out.print("Content: " + post.content)
      end
    end

  fun ref create_post(username: String, subreddit_name: String, title: String, content: String) =>
    try
      let subreddit = subreddits(subreddit_name)?
      if subreddit.create_post(title, content, username) then
        _env.out.print(username + " created a post in " + subreddit_name + ": " + title)
      else
        _env.out.print("Error: " + username + " is not a member of " + subreddit_name)
      end
    end


  fun ref generate_random_string(length: USize = 16): String =>
    let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let builder = String(length)
    
    try
      for i in Range[USize](0, length.usize()) do
        let idx = _random.int(chars.size().u64())
        builder.push(chars(idx.usize())?)
      end
    end
    builder.clone()


  fun ref register_user(username: String) =>
    if not users.contains(username) then
      let new_user = User(_env, username)
      users.insert(username, new_user)
    end

  fun ref create_subreddit(name: String) =>
    if not subreddits.contains(name) then
      let new_subreddit = Subreddit(name)
      subreddits.insert(name, new_subreddit)
    end

  fun ref join_subreddit(username: String, subreddit_name: String) =>
    try
      (let user, let subreddit) = (users(username)?, subreddits(subreddit_name)?)
      subreddit.add_member(username)
    end

  fun ref leave_subreddit(username: String, subreddit_name: String) =>
    try
      (let user, let subreddit) = (users(username)?, subreddits(subreddit_name)?)
      subreddit.remove_member(username)
    end

class Subreddit
  let name: String
  var members: Set[String] ref
  var posts: Array[Post] ref

  new create(name': String) =>
    name = name'
    members = Set[String]
    posts = Array[Post]

  fun ref add_member(username: String) =>
    members.set(username)

  fun ref remove_member(username: String) =>
    members.unset(username)

  fun get_member_count(): USize =>
    members.size()

  fun ref get_members(): Set[String] ref =>  
    members

  fun get_members_clone(): Set[String] =>    
    members.clone()

  fun ref create_post(title: String, content: String, author: String): Bool =>
    if members.contains(author) then
      let post = Post(title, content, author)
      posts.push(post)
      true
    else
      false
    end
    
  fun ref get_posts(): Array[Post] ref =>
    posts

class Post
  let title: String
  let content: String
  let author: String
  
  new create(title': String, content': String, author': String) =>
    title = title'
    content = content'
    author = author'
