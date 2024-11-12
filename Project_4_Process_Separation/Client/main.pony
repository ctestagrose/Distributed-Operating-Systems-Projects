use "net"

actor Main
  new create(env: Env) =>
    let username = try
      env.args(1)?
    else
      env.out.print("Usage: client <username>")
      env.exitcode(1)
      return
    end
    
    RedditClient(env, username)