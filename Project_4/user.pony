actor User
  var _username: String
  let _env: Env

  new create(env:Env, username': String) =>
    _env = env
    _username = username'

  be print_name(env: Env) =>
    env.out.print(_username)

  fun get_username(): String =>
    _username