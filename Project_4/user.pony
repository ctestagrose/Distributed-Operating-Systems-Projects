use "collections"
use "random"
use "time"

actor User
  var _username: String
  let _env: Env
  var _post_karma: I64
  var _comment_karma: I64
  let achievements: Set[String] ref

  new create(env:Env, username': String) =>
    _env = env
    _username = username'
    _post_karma = 0
    _comment_karma = 0
    achievements = Set[String]

  be print_name(env: Env) =>
    env.out.print(_username)

  fun get_username(): String =>
    _username

  be add_post_karma(amount: I64) =>
    _post_karma = _post_karma + amount

  be add_comment_karma(amount: I64) =>
    _comment_karma = _comment_karma + amount

  fun get_post_karma(): I64 =>
    _post_karma

  fun get_comment_karma(): I64 =>
    _comment_karma

  fun get_total_karma(): I64 =>
    _post_karma + _comment_karma

  fun ref check_achievements() =>
    if get_post_karma() > 1000 then
      achievements.set("Popular Poster")
    end
    if get_comment_karma() > 500 then
      achievements.set("Active Commenter")
    end