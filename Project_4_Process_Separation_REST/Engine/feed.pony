use "collections"
use "time"

class PostFeed
  let posts: Array[RedditPost] ref
  let _env: Env
  
  new create(env: Env) =>
    posts = Array[RedditPost]
    _env = env
  
  fun ref add_post(post: RedditPost) =>
    posts.push(post)
  
  fun ref sort_by(sort_type: U8) =>
    match sort_type
    | SortType.hot() => PostSorter.sort_by_hot(posts)
    | SortType.controversial() => PostSorter.sort_by_controversial(posts)
    | SortType.top() => PostSorter.sort_by_top(posts)
    | SortType.new_p() => PostSorter.sort_by_new(posts)
    end
  
  fun ref display(env: Env, limit: USize = 25) =>
    env.out.print("\n=== Feed Posts ===")
    var count: USize = 0
    for post in posts.values() do
      if count >= limit then break end
      env.out.print("\nTitle: " + post.title)
      env.out.print("Author: " + post.author)
      env.out.print("Score: " + post.get_score().string())
      env.out.print("Hot Score: " + post.get_hot_score().string())
      env.out.print("Comments: " + post.get_comments().size().string())
      env.out.print("---")
      count = count + 1
    end

primitive FeedGenerator
  fun apply(env: Env): Feed =>
    Feed(env)

class Feed
  let _env: Env
  
  new create(env: Env) =>
    _env = env

  fun ref generate_user_feed(subreddits: Map[String, Subreddit] ref, username: String, 
    sort_type: U8 = SortType.hot()): PostFeed =>
    let feed = PostFeed(_env)
    for (subreddit_name, subreddit) in subreddits.pairs() do
        if subreddit.get_members().contains(username) then
          for post in subreddit.get_posts().values() do
            feed.add_post(post)
          end
        end
    end
    feed.sort_by(sort_type)

    feed

  fun ref generate_popular_feed(subreddits: Map[String, Subreddit] ref, 
    sort_type: U8 = SortType.hot()): PostFeed =>
    let feed = PostFeed(_env)
    
    for subreddit in subreddits.values() do
        for post in subreddit.get_posts().values() do
            feed.add_post(post)
        end
    end
    feed.sort_by(sort_type)

    feed

  fun ref generate_subreddit_feed(subreddits: Map[String, Subreddit] ref, 
    subreddit_name: String, sort_type: U8 = SortType.hot()): PostFeed? =>
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