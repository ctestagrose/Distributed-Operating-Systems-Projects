use "collections"
use "random"
use "time"

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
  
  new create(env: Env, username: String, bio: String = "") =>
    _env = env
    _profile = UserProfile(username, bio)
    _post_karma = 0
    _comment_karma = 0

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