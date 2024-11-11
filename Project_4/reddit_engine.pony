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
    
    // 1. Create users with bios
    for i in Range[USize](0, num_users.usize()) do
      let random_name = generate_random_string()
      let bio: String = "I'm user " + random_name + " and I love Reddit!"
      register_user(random_name, bio)
      _env.out.print("Registered new user: " + random_name)
    end
    _env.out.print("\nAll registered users: " + ",".join(users.keys()))

    try
      // 2. Get our test users
      var user_iter = users.keys()
      let creator = user_iter.next()?    
      let poster = user_iter.next()?     
      let commenter = user_iter.next()?  
      
      // Create multiple subreddits to test karma tracking across communities
      let subreddits_to_create: Array[String] = ["programming"; "news"; "funny"]
      
      // 3. Create and populate multiple subreddits to test karma tracking
      for subreddit_name in subreddits_to_create.values() do
        _env.out.print("\n=== Testing " + subreddit_name + " Subreddit ===")
        
        // Create subreddit
        _env.out.print("\nCreating subreddit: " + subreddit_name)
        create_subreddit(subreddit_name)
        
        // Have all users join
        join_subreddit(creator, subreddit_name)
        join_subreddit(poster, subreddit_name)
        join_subreddit(commenter, subreddit_name)
        
        // Create some posts
        create_post(creator, subreddit_name, "Welcome to " + subreddit_name, "First post!")
        create_post(poster, subreddit_name, "Question about " + subreddit_name, "What do you think?")
        
        // Add comments
        add_comment(commenter, subreddit_name, 0, "Great subreddit!")
        add_comment(poster, subreddit_name, 0, "Thanks for creating this!")
        add_comment(creator, subreddit_name, 1, "Interesting question!")
        
        // Test voting to generate karma
        vote_on_post(commenter, subreddit_name, 0, true)
        vote_on_post(poster, subreddit_name, 0, true)
        vote_on_post(creator, subreddit_name, 1, true)
        
        vote_on_comment(creator, subreddit_name, 0, 0, true)
        vote_on_comment(poster, subreddit_name, 0, 0, true)

        // Reply to first comment
        let first_comment = Array[USize]
        first_comment.push(0)  // Index of first comment
        add_nested_comment(creator, subreddit_name, 0, first_comment, "Reply to first comment!")
        
        // Reply to second comment
        let second_comment = Array[USize]
        second_comment.push(1)  // Index of second comment
        add_nested_comment(poster, subreddit_name, 0, second_comment, "Reply to second comment!")
        
        // Add nested reply (reply to a reply)
        let nested_reply = Array[USize]
        nested_reply.push(0)  // First comment
        nested_reply.push(0)  // First reply to first comment
        add_nested_comment(commenter, subreddit_name, 0, nested_reply, "This is a nested reply!")
        
        // 7. Test voting on comments
        _env.out.print("\n=== Testing Comment Voting ===")
        // Vote on top-level comment
        vote_on_comment(creator, subreddit_name, 0, 0, true)  // Upvote first comment
        vote_on_comment(poster, subreddit_name, 0, 1, true)   // Upvote second comment
        
        // 8. Display the results
        _env.out.print("\n=== Final Post State ===")
        print_subreddit_posts(subreddit_name)

      end
      
      // 4. Print initial user profiles
      _env.out.print("\n=== Initial User Profiles ===")
      try
        let creator_user = users(creator)?
        let poster_user = users(poster)?
        let commenter_user = users(commenter)?
        
        creator_user.print_profile(_env)
        poster_user.print_profile(_env)
        commenter_user.print_profile(_env)
      end
      
      // 5. Additional activity to test achievement tracking
      let active_subreddit = "programming"
      
      // Add more posts to trigger achievements
      for i in Range(0, 8) do  // This plus earlier posts should trigger Prolific Poster
        create_post(creator, active_subreddit, 
          "Achievement Test Post " + i.string(), "Content " + i.string())
      end
      
      // Add more comments to trigger achievements
      for i in Range(0, 47) do  // This plus earlier comments should trigger Discussion Master
        add_comment(commenter, active_subreddit, 0, 
          "Working towards Discussion Master " + i.string())
      end
      
      // Generate karma to trigger achievements
      for i in Range(0, 100) do  // Generate significant karma
          let post_index = (i % 3).usize()
          vote_on_post(poster, active_subreddit, post_index, true)
          vote_on_comment(creator, active_subreddit, 0, 0, true)
      end
      
      // 6. Print final user profiles showing achievements
      _env.out.print("\n=== Final User Profiles with Achievements ===")
      try
        let creator_user = users(creator)?
        let poster_user = users(poster)?
        let commenter_user = users(commenter)?
        
        creator_user.print_profile(_env)
        poster_user.print_profile(_env)
        commenter_user.print_profile(_env)
      end
      
      // 7. Test profile updates after leaving
      _env.out.print("\n=== Testing Profile Updates After Leaving ===")
      leave_subreddit(commenter, active_subreddit)
      
      try
        let commenter_user = users(commenter)?
        commenter_user.print_profile(_env)
      end
      
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
      let subreddit = subreddits(subreddit_name)?
      if subreddit.create_post(title, content, username) then
        _env.out.print(username + " created a post in " + subreddit_name + ": " + title)
        try
          let user = users(username)?
          user.add_post_karma(1, subreddit_name)
          // Use the subreddit's posts array size - 1 as the post_id
          user.add_post(title, subreddit_name, subreddit.get_posts().size() - 1)
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
          user.add_comment_karma(1, subreddit_name)
          user.add_comment(content, subreddit_name, post_index)
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
      let subreddit = subreddits(subreddit_name)?
      if subreddit.vote_on_post(post_index, username, is_upvote) then
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