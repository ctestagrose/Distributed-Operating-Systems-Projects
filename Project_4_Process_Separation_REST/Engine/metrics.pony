use "collections"
use "time"

class MetricsTracker
  let _env: Env
  var _start_time: I64
  var _total_posts: USize
  var _total_comments: USize
  var _total_votes: USize
  var _total_reposts: USize
  var _total_messages: USize
  var _active_users: Set[String] ref
  let _subreddit_activity: Map[String, SubredditMetrics ref] ref
  let _response_times: Array[F64] ref
  let _user_activity_times: Map[String, Array[I64]] ref
  let _simulated_offline_users: Set[String] ref
  var _total_simulated_users: USize 
  
  new create(env: Env) =>
    _env = env
    _start_time = Time.now()._1
    _total_posts = 0
    _total_comments = 0
    _total_votes = 0
    _total_reposts = 0
    _total_messages = 0
    _active_users = Set[String]
    _subreddit_activity = Map[String, SubredditMetrics ref]
    _response_times = Array[F64]
    _user_activity_times = Map[String, Array[I64]]
    _simulated_offline_users = Set[String]
    _total_simulated_users = 0

  fun ref track_post(subreddit: String, author: String) =>
    _total_posts = _total_posts + 1
    _active_users.set(author)
    _track_user_activity(author)
    _get_or_create_subreddit_metrics(subreddit).add_post()

  fun ref set_initial_users(count: USize) =>
    _total_simulated_users = count

  fun ref track_new_simulated_user(username: String) =>
    _total_simulated_users = _total_simulated_users + 1
    _active_users.set(username)

  fun ref remove_simulated_user(username: String) =>
    if _active_users.contains(username) then
      _total_simulated_users = _total_simulated_users - 1
      _active_users.unset(username)
      _simulated_offline_users.unset(username)
    end


  fun ref track_connection_change(username: String, is_online: Bool) =>
    if is_online then
      _simulated_offline_users.unset(username)
    else
      _simulated_offline_users.set(username)
    end

  fun ref track_repost(subreddit: String, author: String) =>
    _total_reposts = _total_reposts + 1
    _active_users.set(author)
    _track_user_activity(author)
    _get_or_create_subreddit_metrics(subreddit).add_repost()

  fun ref track_comment(subreddit: String, author: String) =>
    _total_comments = _total_comments + 1
    _active_users.set(author)
    _track_user_activity(author)
    _get_or_create_subreddit_metrics(subreddit).add_comment()

  fun ref track_vote(subreddit: String, voter: String) =>
    _total_votes = _total_votes + 1
    _active_users.set(voter)
    _track_user_activity(voter)
    _get_or_create_subreddit_metrics(subreddit).add_vote()

  fun ref track_message(sender: String) =>
    _total_messages = _total_messages + 1
    _active_users.set(sender)
    _track_user_activity(sender)

  fun ref track_response_time(time_ms: F64) =>
    if time_ms > 0 then
      _response_times.push(time_ms)
    end


  fun ref _track_user_activity(username: String) =>
    if not _user_activity_times.contains(username) then
      _user_activity_times(username) = Array[I64]
    end
    try
      _user_activity_times(username)?.push(Time.now()._1)
    end

  fun ref _get_or_create_subreddit_metrics(subreddit: String): SubredditMetrics ref =>
    try
      _subreddit_activity(subreddit)?
    else
      let metrics = SubredditMetrics
      _subreddit_activity(subreddit) = metrics
      metrics
    end

  fun display_metrics() =>
    let current_time = Time.now()._1
    let uptime_hours = (current_time - _start_time).f64() / 3600.0
    
    _env.out.print("\n=== Reddit Clone Metrics Report ===")
    _env.out.print("Uptime: " + uptime_hours.string() + " hours")
    
    _env.out.print("\nOverall Activity:")
    _env.out.print("Total Posts: " + _total_posts.string())
    _env.out.print("Total Comments: " + _total_comments.string())
    _env.out.print("Total Votes: " + _total_votes.string())
    _env.out.print("Total Reposts: " + _total_reposts.string())
    _env.out.print("Total Messages: " + _total_messages.string())
    
    _env.out.print("\nConnection Status:")
    _env.out.print("Total Simulated Users: " + _total_simulated_users.string())
    _env.out.print("Users Online: " + (_total_simulated_users - _simulated_offline_users.size()).string())
    _env.out.print("Users Offline: " + _simulated_offline_users.size().string())
    
    _env.out.print("\nHourly Rates:")
    _env.out.print("Posts/hour: " + (_total_posts.f64() / uptime_hours).string())
    _env.out.print("Comments/hour: " + (_total_comments.f64() / uptime_hours).string())
    _env.out.print("Votes/hour: " + (_total_votes.f64() / uptime_hours).string())
    
    if _response_times.size() > 0 then
      var total: F64 = 0
      var max: F64 = 0
      for time in _response_times.values() do
        total = total + time
        if time > max then max = time end
      end
      let avg = total / _response_times.size().f64()
      _env.out.print("\nResponse Times:")
      _env.out.print("Average: " + avg.string() + " ms")
      _env.out.print("Maximum: " + max.string() + " ms")
    end
    
    _env.out.print("\nSubreddit Activity:")
    for (name, metrics) in _subreddit_activity.pairs() do
      _env.out.print("\nr/" + name + ":")
      _env.out.print("  Posts: " + metrics.posts.string())
      _env.out.print("  Comments: " + metrics.comments.string())
      _env.out.print("  Votes: " + metrics.votes.string())
      _env.out.print("  Reposts: " + metrics.reposts.string())
      let engagement = if metrics.posts > 0 then
        ((metrics.comments.f64() + metrics.votes.f64()) / metrics.posts.f64()).string()
      else
        "0"
      end
      _env.out.print("  Engagement Rate: " + engagement)
    end

  fun get_total_posts(): USize => _total_posts
  fun get_total_comments(): USize => _total_comments
  fun get_total_votes(): USize => _total_votes
  fun get_total_reposts(): USize => _total_reposts
  fun get_total_messages(): USize => _total_messages
  fun get_active_users_count(): USize => _active_users.size()
  fun get_start_time(): I64 => _start_time

  fun get_formatted_metrics(): String val =>
    let response_builder = String(256)
    
    response_builder.append(" ###METRIC### Total_Posts " + _total_posts.string())
    response_builder.append(" ###METRIC### Total_Comments " + _total_comments.string())
    response_builder.append(" ###METRIC### Total_Votes " + _total_votes.string())
    response_builder.append(" ###METRIC### Total_Reposts " + _total_reposts.string())
    response_builder.append(" ###METRIC### Total_Messages " + _total_messages.string())
    response_builder.append(" ###METRIC### Total_Users " + _total_simulated_users.string())
    response_builder.append(" ###METRIC### Users_Online " + (_total_simulated_users - _simulated_offline_users.size()).string())
    response_builder.append(" ###METRIC### Users_Offline " + _simulated_offline_users.size().string())
    
    let uptime = (Time.now()._1 - _start_time).f64() / 3600.0
    if uptime > 0 then
      let posts_per_hour = _total_posts.f64() / uptime
      let comments_per_hour = _total_comments.f64() / uptime
      let votes_per_hour = _total_votes.f64() / uptime
      
      response_builder.append(" ###METRIC### Posts_Per_Hour " + posts_per_hour.string())
      response_builder.append(" ###METRIC### Comments_Per_Hour " + comments_per_hour.string())
      response_builder.append(" ###METRIC### Votes_Per_Hour " + votes_per_hour.string())
    end

    if _response_times.size() > 0 then
      var total: F64 = 0
      var max: F64 = 0
      for time in _response_times.values() do
        total = total + time
        if time > max then max = time end
      end
      let avg = total / _response_times.size().f64()
      _env.out.print("\nResponse Times:")
      _env.out.print("Average: " + avg.string() + " ms (from " + _response_times.size().string() + " requests)")
      _env.out.print("Maximum: " + max.string() + " ms")
    end

    recover val response_builder.clone() end

  fun get_response_times(): Array[F64] val =>
    let arr = recover trn Array[F64] end
    for t in _response_times.values() do
      arr.push(t)
    end
    consume arr
    

class SubredditMetrics
  var posts: USize = 0
  var comments: USize = 0
  var votes: USize = 0
  var reposts: USize = 0
  
  new create() =>
    None
    
  fun ref add_post() => posts = posts + 1
  fun ref add_comment() => comments = comments + 1
  fun ref add_vote() => votes = votes + 1
  fun ref add_repost() => reposts = reposts + 1