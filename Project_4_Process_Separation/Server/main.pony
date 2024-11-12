use "net"

actor Main
  new create(env: Env) =>
    let auth = TCPListenAuth(env.root)
    RedditServer(env, auth)