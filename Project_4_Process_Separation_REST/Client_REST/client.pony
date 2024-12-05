use "net"
use "collections"
use "format"
use "time"

primitive GET
primitive POST
primitive PUT
primitive DELETE

type Method is (GET | POST | PUT | DELETE)

actor RedditClient
  let _env: Env
  let _auth: TCPConnectAuth
  let _host: String
  let _port: String
  var _conn: (TCPConnection tag | None)
  let _username: String
  
  new create(env: Env, username: String, host: String = "localhost", port: String = "8080") =>
    _env = env
    _auth = TCPConnectAuth(env.root)
    _host = host
    _port = port
    _username = username
    _conn = None
    
    _connect()
    
  fun ref _connect() =>
    _conn = TCPConnection(
      _auth,
      recover HTTPClientNotify(this) end,
      _host,
      _port
    )

  be connected() =>
    _env.out.print("Connected to Reddit server")
    register_user()

  be register_user() =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"bio\":\"A Reddit Clone user\"")
      json.append("}")
      json
    end
    
    _send_request(POST, "/users", headers, body)

  be subscribe_to_subreddit(subreddit: String) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\"")
      json.append("}")
      json
    end

    _send_request(POST, "/subreddits/" + subreddit + "/subscribe", headers, body)

  be list_subreddits() =>
    let headers = recover val Map[String, String] end
    _send_request(GET, "/subreddits", headers, "")

  be create_post(subreddit: String, title: String, content: String) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"title\":\"" + title + "\",")
      json.append("\"content\":\"" + content + "\"")
      json.append("}")
      json
    end
    
    _send_request(POST, "/subreddits/" + subreddit + "/posts", headers, body)

  be vote_on_post(subreddit: String, post_id: USize, is_upvote: Bool) =>
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"username\":\"" + _username + "\",")
      json.append("\"subreddit\":\"" + subreddit + "\",")
      json.append("\"upvote\":" + if is_upvote then "true" else "false" end)
      json.append("}")
      json
    end
    
    _send_request(POST, "/posts/" + post_id.string() + "/vote", headers, body)

  fun ref _send_request(method: Method, path: String, headers: Map[String, String] val, body: String val) =>
    try
      let conn = _conn as TCPConnection tag
      let request = _build_request(method, path, headers, body)
      _env.out.print("Sending request:\n" + request.clone())
      conn.write(consume request)
    else
      _env.out.print("Error: Not connected to server")
    end

  fun ref _build_request(method: Method, path: String, headers: Map[String, String] val, body: String): String iso^ =>
    let request = recover iso String end
    
    let method_str = match method
    | GET => "GET"
    | POST => "POST"
    | PUT => "PUT"
    | DELETE => "DELETE"
    end
    
    request.append(method_str + " " + path + " HTTP/1.1\r\n")
    request.append("Host: " + _host + ":" + _port + "\r\n")
    
    if body.size() > 0 then
      request.append("Content-Length: " + body.size().string() + "\r\n")
    end
    
    for (name, value) in headers.pairs() do
      request.append(name + ": " + value + "\r\n")
    end
    
    request.append("\r\n")
    if body.size() > 0 then
      request.append(body)
    end
    
    consume request


  be received(data: Array[U8] val) =>
    let response = String.from_array(data)
    _env.out.print("Received response:\n" + response)
    
    // After registration, try to join programming subreddit
    if response.contains("User created") then
      subscribe_to_subreddit("programming")
    // After joining subreddit, create a test post
    elseif response.contains("Subscribed to subreddit") then
      create_post("programming", "My First Post", "Hello Reddit Clone!")
    end

  be closed() =>
    _env.out.print("Disconnected from Reddit server")
    _conn = None

class HTTPClientNotify is TCPConnectionNotify
  let _client: RedditClient
  
  new iso create(client: RedditClient) =>
    _client = client
  
  fun ref connected(conn: TCPConnection ref) =>
    _client.connected()
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _client.received(consume data)
    true
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    None
  
  fun ref closed(conn: TCPConnection ref) =>
    _client.closed()

actor Main
  new create(env: Env) =>
    try
      let username = env.args(1)?
      let client = RedditClient(env, username)
      
      // Register the user first
      client.register_user()
      
      // Wait a bit then try to subscribe to a subreddit
      let timers = Timers(20)
      let timer = Timer(
        object iso is TimerNotify
          let _client: RedditClient = client
          
          fun ref apply(timer: Timer, count: U64): Bool =>
            _client.subscribe_to_subreddit("programming")
            false
        end,
        1_000_000_000, // 1 second
        0
      )
      timers(consume timer)
    else
      env.out.print("Usage: client <username>")
      env.exitcode(1)
    end


