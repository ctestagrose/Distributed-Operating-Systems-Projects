
actor Main
  new create(env: Env) =>
    try
      let args = env.args
      let num_users = args(1)?.u64()?
      
      let engine = RedditEngine
      engine.run(env, num_users)
    else
      env.out.print("Usage: ./implementation numUsers")
    end
