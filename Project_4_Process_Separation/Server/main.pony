use "net"

actor Main
  new create(env: Env) =>
  let num_clients = try
      env.args(1)?
    else
      env.out.print("Usage: Server <num_clients>")
      env.exitcode(1)
      return
    end
  let auth = TCPListenAuth(env.root)
  RedditServer(env, auth, num_clients)