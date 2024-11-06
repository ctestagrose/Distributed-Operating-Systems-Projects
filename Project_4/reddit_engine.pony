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
      
       // 7b. Test different sort orders
      _env.out.print("\n=== Testing Post Sorting ===")
      
      // Add more posts with different scores and times for better testing
      create_post(creator, subreddit_name, "Second Post", "Testing sorting!")
      create_post(poster, subreddit_name, "Third Post", "More testing content")

            // Add some votes to create different scores
      vote_on_post(commenter, subreddit_name, 1, true)  // Upvote second post
      vote_on_post(creator, subreddit_name, 1, true)
      vote_on_post(poster, subreddit_name, 2, true)
      vote_on_post(creator, subreddit_name, 2, false)  // Downvote third post
      
      _env.out.print("\nSorting by Hot:")
      print_sorted_posts(subreddit_name, SortType.hot())
      
      _env.out.print("\nSorting by Controversial:")
      print_sorted_posts(subreddit_name, SortType.controversial())
      
      _env.out.print("\nSorting by Top:")
      print_sorted_posts(subreddit_name, SortType.top())
      
      _env.out.print("\nSorting by New:")
      print_sorted_posts(subreddit_name, SortType.new_p())

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
        // Add initial karma for self-upvote
        try
          let user = users(username)?
          user.add_post_karma(1)
        end
      else
        _env.out.print("Error: " + username + " is not a member of " + subreddit_name)
      end
    end

  fun ref print_sorted_posts(subreddit_name: String, sort_type: U8) =>
    try
      let sub = subreddits(subreddit_name)?
      let sorted_posts = sub.get_sorted_posts(sort_type)
      _env.out.print("\nSorted Posts in " + subreddit_name + ":")
      
      let sort_name = match sort_type
      | SortType.hot() => "Hot"
      | SortType.controversial() => "Controversial"
      | SortType.top() => "Top"
      | SortType.new_p() => "New"
      else
        "Unknown"
      end
      
      _env.out.print("Sort type: " + sort_name)
      
      for post in sorted_posts.values() do
        _env.out.print("\nTitle: " + post.title)
        _env.out.print("Author: " + post.author)
        _env.out.print("Score: " + post.get_score().string())
        _env.out.print("Hot Score: " + post.get_hot_score().string())
        _env.out.print("Controversy Score: " + post.get_controversy_score().string())
        _env.out.print("Created At: " + post.created_at.string())
        _env.out.print("---")
      end
    end


  fun ref add_comment(username: String, subreddit_name: String, post_index: USize, content: String) =>
    try
      let subreddit = subreddits(subreddit_name)?
      if subreddit.add_comment_to_post(post_index, username, content) then
        _env.out.print(username + " commented on post " + post_index.string())
        try
          let user = users(username)?
          user.add_comment_karma(1)
        end
      else
        _env.out.print("Error: Could not add comment")
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
        
        // Update comment author's karma
        try
          let comment = subreddit.get_posts()(post_index)?.get_comments()(comment_index)?
          let author = users(comment.get_author())?
          if is_upvote then
            author.add_comment_karma(1)
          else
            author.add_comment_karma(-1)
          end
        end
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
        
        // Update post author's karma
        try
          let post = subreddit.get_posts()(post_index)?
          let author = users(post.author)?
          if is_upvote then
            author.add_post_karma(1)
          else
            author.add_post_karma(-1)
          end
        end
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
