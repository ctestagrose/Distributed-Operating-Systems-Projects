use "collections"
use "random"
use "time"


class RedditEngine
  var users: Map[String, User] ref
  var subreddits: Map[String, Subreddit] ref
  let _random: Random
  let _env: Env
  let _feed_generator: Feed
  let _metrics: MetricsTracker

  new create(env: Env) =>
    _env = env
    users = Map[String, User]
    subreddits = Map[String, Subreddit]
    _random = Rand(Time.now()._2.u64())
    _feed_generator = Feed(env)
    _metrics = MetricsTracker(env)


fun ref run(num_users: U64) =>
    _env.out.print("Starting Reddit Engine Simulation with " + num_users.string())
    
    // Initialize common subreddits
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
    
    // Create default subreddits
    for name in default_subreddits.values() do
      create_subreddit(name)
      _env.out.print("Created subreddit: " + name)
    end
    
    // Create initial set of users (smaller number to start)
    // let initial_users = num_users.usize().min(100) 
    let initial_users = num_users.usize()
    for user_idx in Range[USize](0, initial_users) do
      let new_username = generate_random_string()
      let bio = recover val "Redditor since " + Time.now()._1.string() end
      register_user(new_username, consume bio)
      
      // Each initial user joins 2-6 random subreddits
      let num_subs_to_join = _random.int(3).usize() + 4
      var joined = Set[USize]
      
      for i in Range(0, num_subs_to_join) do
        try
          var sub_idx = _random.int(default_subreddits.size().u64()).usize()
          while joined.contains(sub_idx) do
            sub_idx = _random.int(default_subreddits.size().u64()).usize()
          end
          joined.set(sub_idx)
          join_subreddit(new_username, default_subreddits(sub_idx)?)
        end
      end
    end
    
    _env.out.print("\nSimulation initialization complete!")
    _env.out.print("Created " + initial_users.string() + " initial users")
    _env.out.print("Use the simulation timer to generate ongoing activity.")
    
    _env.out.print("\nSimulation initialization complete!")
    _env.out.print("Use the simulation timer to generate ongoing activity.")



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
        
        // Print comment tree
        let comments = post.get_comments()
        if comments.size() > 0 then
          _env.out.print("\nComments:")
          print_comment_tree(comments)
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
      let start_time = Time.now()._2
      let subreddit = subreddits(subreddit_name)?
      if subreddit.create_post(title, content, username) then
        _metrics.track_post(subreddit_name, username)
        _env.out.print(username + " created a post in " + subreddit_name + ": " + title)
        try
          let user = users(username)?
          user.add_post_karma(1, subreddit_name)
          user.add_post(title, subreddit_name, subreddit.get_posts().size() - 1)
        end
      else
        _env.out.print("Error: " + username + " is not a member of " + subreddit_name)
      end
      let end_time = Time.now()._2
      _metrics.track_response_time((end_time - start_time).f64() / 1000000.0)
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
      let start_time = Time.now()._2
      let subreddit = subreddits(subreddit_name)?
      if subreddit.add_comment_to_post(post_index, username, content) then
        _metrics.track_comment(subreddit_name, username)
        _env.out.print(username + " commented on post " + post_index.string())
        try
          let user = users(username)?
          user.add_comment_karma(1, subreddit_name)
          user.add_comment(content, subreddit_name, post_index)
        end
      else
        _env.out.print("Error: Could not add comment")
      end
      let end_time = Time.now()._2
      _metrics.track_response_time((end_time - start_time).f64() / 1000000.0)
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
        
        // Update comment author's karma with subreddit
        try
          let comment = subreddit.get_posts()(post_index)?.get_comments()(comment_index)?
          let author = users(comment.get_author())?
          if is_upvote then
            author.add_comment_karma(1, subreddit_name)
          else
            author.add_comment_karma(-1, subreddit_name)
          end
        end
      end
    end

  fun ref vote_on_post(username: String, subreddit_name: String, post_index: USize, is_upvote: Bool) =>
    try
      let start_time = Time.now()._2
      let subreddit = subreddits(subreddit_name)?
      if subreddit.vote_on_post(post_index, username, is_upvote) then
        _metrics.track_vote(subreddit_name, username)
        var up_or_down = ""
        if is_upvote then 
          up_or_down = " upvoted "
        else 
          up_or_down = " downvoted " 
        end
        _env.out.print(username + " "+ up_or_down + " post " + post_index.string())
        
        // Update post author's karma with subreddit
        try
          let post = subreddit.get_posts()(post_index)?
          let author = users(post.author)?
          if is_upvote then
            author.add_post_karma(1, subreddit_name)
          else
            author.add_post_karma(-1, subreddit_name)
          end
        end
      end
      let end_time = Time.now()._2
      _metrics.track_response_time((end_time - start_time).f64() / 1000000.0)
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


  fun ref register_user(username: String, bio: String = "") =>
    if not users.contains(username) then
      let new_user = User(_env, username, bio)
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


  fun ref add_nested_comment(username: String, subreddit_name: String, post_index: USize, 
    parent_indices: Array[USize], content: String) =>
    try
      let subreddit = subreddits(subreddit_name)?
      if subreddit.add_nested_comment(post_index, parent_indices, username, content) then
        let level = parent_indices.size()
        let spaces = "  ".mul(level)  // Use string multiplication directly
        _env.out.print(spaces + username + " replied to comment at level " + level.string())
        try
          let user = users(username)?
          user.add_comment_karma(1, subreddit_name)
          user.add_comment(content, subreddit_name, post_index)
        end
      else
        _env.out.print("Error: Could not add nested comment")
      end
    end

  fun ref print_comment_tree(comments: Array[Comment] ref, indent: String = "  ") =>
    for comment in comments.values() do
      _env.out.print(indent + comment.get_author() + ": " + comment.get_content() + 
        " [Score: " + comment.get_score().string() + "]")
      print_comment_tree(comment.get_replies(), indent + "  ")
    end

  fun ref show_user_messages(username: String) =>
    """
    Display all messages for a user
    """
    try
      let user = users(username)?
      user.get_messages(_env)
    end

  fun ref show_message_thread(username: String, thread_id: String val) =>
    try
      let user = users(username)?
      user.get_message_thread(_env, thread_id)
    end

  fun ref send_direct_message(from_username: String, to_username: String, content: String, thread_id: String val = "") =>
    try
      let start_time = Time.now()._2
      let sender = users(from_username)?
      let recipient = users(to_username)?
      
      _metrics.track_message(from_username)
      
      _env.out.print(from_username + " sending message to " + to_username)
      
      let message_id: String val = (Time.now()._1.string() + "_" + from_username).clone().string()
      let actual_thread_id: String val = if thread_id == "" then 
        message_id 
      else 
        thread_id
      end
      
      let message = Message(
        from_username.clone().string(),
        to_username.clone().string(),
        content.clone().string(),
        message_id,
        actual_thread_id
      )
      
      sender.send_message(to_username.clone().string(), content.clone().string(), actual_thread_id)
      recipient.receive_message(message)
      let end_time = Time.now()._2
      _metrics.track_response_time((end_time - start_time).f64() / 1000000.0)
    else
      _env.out.print("Error: Could not send message")
    end


  fun ref generate_subreddit_feed(subreddit_name: String, sort_type: U8 = SortType.hot()): PostFeed? =>
    try
      let subreddit = subreddits(subreddit_name)?
      let feed = PostFeed(_env)
      for post in subreddit.get_posts().values() do
        feed.add_post(post)
      end
      feed.sort_by(sort_type)
      feed
    else
      error
    end

  fun ref test_feeds() =>
    try
      var user_iter = users.keys()
      let test_user = user_iter.next()?
      
      _env.out.print("\n=== Testing Feed Generation ===")
      
      // Test user's personal feed
      _env.out.print("\nUser's Personal Feed (Hot):")
      let user_feed = get_user_feed(test_user)
      user_feed.display(_env)
      
      // Test popular feed with different sorts
      _env.out.print("\nPopular Feed (Top):")
      let popular_feed = get_popular_feed(SortType.top())
      popular_feed.display(_env)
      
      _env.out.print("\nPopular Feed (Controversial):")
      let controversial_feed = get_popular_feed(SortType.controversial())
      controversial_feed.display(_env)
      
      // Test subreddit feed
      _env.out.print("\nProgramming Subreddit Feed (New):")
      try
        let subreddit_feed = get_subreddit_feed("programming", SortType.new_p())?
        subreddit_feed.display(_env)
      end
    end

  fun ref get_user_feed(username: String, sort_type: U8 = SortType.hot()): PostFeed =>
    _feed_generator.generate_user_feed(subreddits, username, sort_type)

  fun ref get_popular_feed(sort_type: U8 = SortType.hot()): PostFeed =>
    _feed_generator.generate_popular_feed(subreddits, sort_type)

  fun ref get_subreddit_feed(subreddit_name: String, sort_type: U8 = SortType.hot()): PostFeed? =>
    _feed_generator.generate_subreddit_feed(subreddits, subreddit_name, sort_type)?

  fun ref repost(original_subreddit: String, post_index: USize, target_subreddit: String, reposter: String): Bool =>
    try
      let start_time = Time.now()._2
      let source_sub = subreddits(original_subreddit)?
      let target_sub = subreddits(target_subreddit)?
      let original_post = source_sub.get_posts()(post_index)?
      
      let repost_title = recover val "[Repost] " + original_post.title end
      let repost_content = recover val original_post.content + "\n\nOriginal by u/" + 
        original_post.author + " in r/" + original_subreddit end
      
      if target_sub.create_post(repost_title, repost_content, reposter) then
        _metrics.track_repost(target_subreddit, reposter)
        let end_time = Time.now()._2
        _metrics.track_response_time((end_time - start_time).f64() / 1000000.0)
        true
      else
        false
      end
    else
      false
    end

  fun ref display_metrics() =>
    _metrics.display_metrics()

  fun get_metrics_string(): String val =>
    _metrics.get_formatted_metrics()

primitive ZipfDistribution
  fun apply(rank: USize, total_items: USize, s: F64 = 1.0): F64 =>
    let rank_f = rank.f64()
    let harmonic = _harmonic_number(total_items, s)
    (1.0 / (rank_f.pow(s))) / harmonic

  fun _harmonic_number(n: USize, s: F64): F64 =>
    var sum: F64 = 0
    for n_idx in Range(1, n + 1) do
      sum = sum + (1.0 / n_idx.f64().pow(s))
    end
    sum

  fun distribute_users(num_users: USize, num_subreddits: USize, s: F64 = 1.0, 
    rand: Random): Array[USize] =>
    let distribution = Array[USize].init(0, num_subreddits)
    
    // Calculate probabilities for each rank
    let probabilities = Array[F64].init(0, num_subreddits)
    for rank in Range(1, num_subreddits + 1) do
      probabilities.push(apply(rank, num_subreddits, s))
    end
    
    // Assign users based on probabilities
    for user_num in Range(0, num_users) do
      var random_value = rand.real()
      var cumulative: F64 = 0
      
      for prob_idx in Range(0, num_subreddits) do
        try
          cumulative = cumulative + probabilities(prob_idx)?
          if random_value <= cumulative then
            try distribution(prob_idx)? = distribution(prob_idx)? + 1 end
            break
          end
        end
      end
    end
    
    distribution
