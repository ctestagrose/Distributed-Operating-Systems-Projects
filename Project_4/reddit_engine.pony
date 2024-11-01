use "collections"
use "random"
use "time"

class RedditEngine
  var users: Map[String, User] ref
  var subreddits: Map[String, Subreddit] ref
  let _random: Random


  new create() =>
    users = Map[String, User]
    subreddits = Map[String, Subreddit]
    _random = Rand(Time.now()._2.u64())


  fun ref run(env: Env, num_users: U64) =>
    env.out.print("Welcome to the Reddit Engine Simulator!")
    
    for i in Range[USize](0, num_users.usize()) do
      let random_name = generate_random_string()
      register_user(random_name)
      env.out.print("Registered new user: " + random_name)
    end

    env.out.print("\nAll registered users: " + ",".join(users.keys()))


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
      let new_user = User(username)
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
      subreddit.add_member(user)
    end


class User
  var username: String

  new create(username': String) =>
    username = username'

  fun print_name(env: Env) =>
    env.out.print(username)

  

class Subreddit
  let name: String
  var members: Set[String] ref

  new create(name': String) =>
    name = name'
    members = Set[String]

  fun ref add_member(user: User) =>
    members.set(user.username)

  fun ref remove_member(user: User) =>
    members.unset(user.username)

  fun get_member_count(): USize =>
    members.size()

  fun ref get_members(): Set[String] ref =>  
    members

  fun get_members_clone(): Set[String] =>    
    members.clone()
