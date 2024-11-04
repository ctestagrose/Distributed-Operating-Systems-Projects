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
    
    // 1. Create users
    for i in Range[USize](0, num_users.usize()) do
      let random_name = generate_random_string()
      register_user(random_name)
      _env.out.print("Registered new user: " + random_name)
    end
    _env.out.print("\nAll registered users: " + ",".join(users.keys()))

    try
      // 2. Get our test users
      var user_iter = users.keys()
      let creator = user_iter.next()?    // First user - will create subreddit
      let poster = user_iter.next()?     // Second user - will create first post
      let commenter = user_iter.next()?  // Third user - will comment on post
      
      let subreddit_name = "programming"
      
      // 3. Test subreddit creation
      _env.out.print("\n=== Testing Subreddit Creation ===")
      _env.out.print("User " + creator + " is creating subreddit: " + subreddit_name)
      create_subreddit(subreddit_name)
      join_subreddit(creator, subreddit_name)
      
      // 4. Have users join
      _env.out.print("\n=== Testing Join Functionality ===")
      join_subreddit(poster, subreddit_name)
      _env.out.print(poster + " joined " + subreddit_name)
      join_subreddit(commenter, subreddit_name)
      _env.out.print(commenter + " joined " + subreddit_name)
      
      // Add remaining users
      for username in user_iter do
        join_subreddit(username, subreddit_name)
        _env.out.print(username + " joined " + subreddit_name)
      end
      
      // 5. Test posting
      _env.out.print("\n=== Testing Posting Functionality ===")
      create_post(poster, subreddit_name, "First Post!", "Hello World!")
      
      // 6. Test commenting
      _env.out.print("\n=== Testing Comment Functionality ===")
      add_comment(commenter, subreddit_name, 0, "Great first post!")
      add_comment(poster, subreddit_name, 0, "Thanks for the comment!")
      add_comment(creator, subreddit_name, 0, "Welcome to the subreddit!")

      // 7. Test voting
      _env.out.print("\n=== Testing Voting Functionality ===")
      // Vote on post
      vote_on_post(creator, subreddit_name, 0, true)  // Creator upvotes
      vote_on_post(commenter, subreddit_name, 0, true)  // Commenter upvotes
      vote_on_post(poster, subreddit_name, 0, false)  // Poster downvotes (testing)

      // Vote on comments
      vote_on_comment(creator, subreddit_name, 0, 0, true)  // Vote on first comment
      vote_on_comment(poster, subreddit_name, 0, 0, true)   
      vote_on_comment(commenter, subreddit_name, 0, 1, false)  // Vote on second comment
      
      // 8. Display current state
      _env.out.print("\n=== Current Subreddit State ===")
      print_subreddit_stats(subreddit_name)
      print_subreddit_posts(subreddit_name)
      
      // 9. Test leaving
      _env.out.print("\n=== Testing Leave Functionality ===")
      _env.out.print("User " + commenter + " is leaving " + subreddit_name)
      leave_subreddit(commenter, subreddit_name)
      
      // 10. Display final state
      _env.out.print("\n=== Final Subreddit State ===")
      print_subreddit_stats(subreddit_name)
    else
      _env.out.print("Error: Need at least 3 users to test all functionality")
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
        _env.out.print("Score: " + post.get_score().string())
        
        // Print comments
        let comments = post.get_comments()
        if comments.size() > 0 then
          _env.out.print("\nComments:")
          for comment in comments.values() do
            _env.out.print("  " + comment.get_author() + ": " + comment.get_content() + 
              " [Score: " + comment.get_score().string() + "]")
          end
        end
        _env.out.print("---")
      end
    end

  fun ref print_subreddit_stats(subreddit_name: String) =>
    try
      let sub = subreddits(subreddit_name)?
      _env.out.print("\nSubreddit " + subreddit_name + " stats:")
      _env.out.print("Member count: " + sub.get_member_count().string())
      _env.out.print("Members: " + ",".join(sub.get_members_clone().values()))
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


  fun ref add_comment(username: String, subreddit_name: String, post_index: USize, content: String) =>
    try
      let subreddit = subreddits(subreddit_name)?
      if subreddit.add_comment_to_post(post_index, username, content) then
        _env.out.print(username + " commented on post " + post_index.string())
      else
        _env.out.print("Error: " + username + " could not comment (either not a member or invalid post)")
      end
    end
  
  fun ref vote_on_comment(username: String, subreddit_name: String, post_index: USize, 
    comment_index: USize, is_upvote: Bool) =>
    try
      let subreddit = subreddits(subreddit_name)?
      if subreddit.vote_on_comment(post_index, comment_index, username, is_upvote) then
        var up_or_down = ""
        if is_upvote then 
          up_or_down = " upvoted "
        else 
          up_or_down = " downvoted " 
        end
        _env.out.print(username + " "+ up_or_down + 
          " comment " + comment_index.string() + " on post " + post_index.string())
      end
    end

  fun ref vote_on_post(username: String, subreddit_name: String, post_index: USize, is_upvote: Bool) =>
    try
      let subreddit = subreddits(subreddit_name)?
      if subreddit.vote_on_post(post_index, username, is_upvote) then
        var up_or_down = ""
        if is_upvote then 
          up_or_down = " upvoted "
        else 
          up_or_down = " downvoted " 
        end
        _env.out.print(username + " "+ up_or_down + " post " + post_index.string())
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

  fun ref add_comment_to_post(post_index: USize, author: String, content: String): Bool =>
    try
      if members.contains(author) then
        posts(post_index)?.add_comment(author, content)
        true
      else
        false
      end
    else
      false
    end

  fun ref vote_on_post(post_index: USize, username: String, is_upvote: Bool): Bool =>
    try
      if members.contains(username) then
        let post = posts(post_index)?
        if is_upvote then
          post.upvote(username)
        else
          post.downvote(username)
        end
        true
      else
        false
      end
    else
      false
    end

  fun ref vote_on_comment(post_index: USize, comment_index: USize, username: String, is_upvote: Bool): Bool =>
    try
      if members.contains(username) then
        let comment = posts(post_index)?.get_comments()(comment_index)?
        if is_upvote then
          comment.upvote(username)
        else
          comment.downvote(username)
        end
        true
      else
        false
      end
    else
      false
    end



class Post
  let title: String
  let content: String
  let author: String
  var comments: Array[Comment] ref
  var upvotes: Set[String] ref
  var downvotes: Set[String] ref
  
  new create(title': String, content': String, author': String) =>
    title = title'
    content = content'
    author = author'
    comments = Array[Comment]
    upvotes = Set[String]
    downvotes = Set[String]
    
  fun ref add_comment(comment_author: String, comment_content: String) =>
    let comment = Comment(comment_author, comment_content)
    comments.push(comment)
    
  fun ref get_comments(): Array[Comment] ref =>
    comments

  fun ref upvote(username: String) =>
    downvotes.unset(username)  // Remove downvote if exists
    upvotes.set(username)
    
  fun ref downvote(username: String) =>
    upvotes.unset(username)    // Remove upvote if exists
    downvotes.set(username)
    
  fun get_score(): I64 =>
    upvotes.size().i64() - downvotes.size().i64()



class Comment
  let author: String
  let content: String
  var replies: Array[Comment] ref
  var upvotes: Set[String] ref
  var downvotes: Set[String] ref
  
  new create(author': String, content': String) =>
    author = author'
    content = content'
    replies = Array[Comment]
    upvotes = Set[String]
    downvotes = Set[String]
    
  fun ref add_reply(reply: Comment) =>
    replies.push(reply)
    
  fun get_author(): String =>
    author
    
  fun get_content(): String =>
    content
    
  fun ref get_replies(): Array[Comment] ref =>
    replies

  fun ref upvote(username: String) =>
    downvotes.unset(username)  // Remove downvote if exists
    upvotes.set(username)
    
  fun ref downvote(username: String) =>
    upvotes.unset(username)    // Remove upvote if exists
    downvotes.set(username)

  fun get_score(): I64 =>
    upvotes.size().i64() - downvotes.size().i64()

