use "net"
use "collections"
use "format"
use "../Engine"

primitive GET
primitive POST
primitive PUT
primitive DELETE

type Method is (GET | POST | PUT | DELETE)

class val RoutePattern
  let segments: Array[String] val
  let param_indices: Map[String, USize] val

  new val create(path: String) =>
    let segs = recover trn Array[String] end
    let params = recover trn Map[String, USize] end

    let parts = recover val path.split("/") end
    var idx: USize = 0
    try
      for i in Range(0, parts.size()) do
        let part = parts(i)?
        if part != "" then
          segs.push(part)
          if part.substring(0, 1) == ":" then
            params(part.substring(1)) = idx
          end
          idx = idx + 1
        end
      end
    end

    segments = consume segs
    param_indices = consume params

  fun matches(path: String): (Bool, Map[String, String] val) =>
    let params = recover trn Map[String, String] end
    let parts = recover val path.split("/") end
    let request_segments = recover trn Array[String] end

    try
      for i in Range(0, parts.size()) do
        let part = parts(i)?
        if part != "" then
          request_segments.push(part)
        end
      end
    end

    if request_segments.size() != segments.size() then
      (false, recover val Map[String, String] end)
    else
      try
        var is_match = true
        for i in Range(0, segments.size()) do
          let pattern_seg = segments(i)?
          let request_seg = request_segments(i)?

          if pattern_seg.substring(0, 1) == ":" then
            params(pattern_seg.substring(1)) = request_seg
          elseif pattern_seg != request_seg then
            is_match = false
            break
          end
        end
        (is_match, consume val params)
      else
        (false, recover val Map[String, String] end)
      end
    end

class val Route
  let method: Method
  let pattern: RoutePattern
  let handler: {(HTTPRequest, Map[String, String] val): HTTPResponse} val

  new val create(method': Method, path: String, 
    handler': {(HTTPRequest, Map[String, String] val): HTTPResponse} val) =>
    method = method'
    pattern = RoutePattern(path)
    handler = handler'

  fun matches(request: HTTPRequest): (Bool, HTTPResponse) =>
    (let is_match, let params) = pattern.matches(request.path)
    if (method is request.method) and is_match then
      (true, handler(request, params))
    else
      (false, HTTPResponse(404, recover val Map[String, String] end, "Not Found\n"))
    end

class val HTTPRequest
  let method: Method
  let path: String
  let headers: Map[String, String] val
  let body: String
  
  new val create(method': Method, path': String, 
    headers': Map[String, String] val, body': String) =>
    method = method'
    path = path'
    headers = headers'
    body = body'

class val HTTPResponse
  let status: U16
  let headers: Map[String, String] val
  let body: String

  new val create(status': U16, headers': Map[String, String] val, body': String) =>
    status = status'
    headers = headers'
    body = body'

  fun string(): String =>
    let status_text = match status
      | 200 => "OK"
      | 201 => "Created"
      | 204 => "No Content"
      | 400 => "Bad Request"
      | 401 => "Unauthorized"
      | 404 => "Not Found"
      | 405 => "Method Not Allowed"
      | 500 => "Internal Server Error"
      else
        "Unknown"
      end

    let response = recover iso String end
    response.append("HTTP/1.1 " + status.string() + " " + status_text + "\r\n")

    // Default headers
    response.append("Connection: close\r\n")

    // Add custom headers
    for (name, value) in headers.pairs() do
      response.append(name + ": " + value + "\r\n")
    end

    // Add Content-Length
    response.append("Content-Length: " + body.size().string() + "\r\n")

    // Add Content-Type if not already present
    if not headers.contains("Content-Type") then
      response.append("Content-Type: text/plain\r\n")
    end

    response.append("\r\n")
    response.append(body)

    consume response

actor HTTPServer
  let _env: Env
  let _auth: TCPListenAuth
  let _connections: SetIs[TCPConnection tag]
  let _routes: Array[Route]
  let _reddit_engine: RedditEngine ref
  
  new create(env: Env, auth: TCPListenAuth) =>
    _env = env
    _auth = auth
    _connections = SetIs[TCPConnection tag]
    _reddit_engine = RedditEngine(env) // Instantiate RedditEngine
    _routes = Array[Route].create()

    // Initialize routes as before...
    initialize_routes()

    TCPListener(auth, recover HTTPServerListener(this, env) end, "localhost", "8080")

  fun ref initialize_routes() =>
    
    // Root route
    _routes.push(Route(GET, "/", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      let headers = recover val Map[String, String] end
      HTTPResponse(200, headers, "Welcome to Reddit Clone API!\n")
    }))

    // User routes
    _routes.push(Route(POST, "/users", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      let headers = recover val Map[String, String] end
      HTTPResponse(201, headers, "User created successfully\n")
    }))

    _routes.push(Route(POST, "/users/login", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      let headers = recover val Map[String, String] end
      HTTPResponse(200, headers, "Login successful\n")
    }))

    _routes.push(Route(GET, "/users/:username/profile", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      try
        let username = params("username")?
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "Profile for user: " + username + "\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "Invalid username parameter\n")
      end
    }))

    // Subreddit routes
    _routes.push(Route(GET, "/subreddits", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      let headers = recover val Map[String, String] end
      HTTPResponse(200, headers, "List of subreddits\n")
    }))

    _routes.push(Route(POST, "/subreddits", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      let headers = recover val Map[String, String] end
      HTTPResponse(201, headers, "Subreddit created successfully\n")
    }))

    _routes.push(Route(GET, "/subreddits/:name", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      try
        let name = params("name")?
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "Details for subreddit: " + name + "\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "Invalid subreddit name parameter\n")
      end
    }))

    _routes.push(Route(POST, "/subreddits/:name/join", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      try
        let name = params("name")?
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "Joined subreddit: " + name + "\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "Invalid subreddit name parameter\n")
      end
    }))

    // Post routes
    _routes.push(Route(POST, "/posts/:id/comment", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      try
        let post_id = params("id")?
        let headers = recover val Map[String, String] end
        HTTPResponse(201, headers, "Added comment to post: " + post_id + "\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "Invalid post ID parameter\n")
      end
    }))

    _routes.push(Route(POST, "/posts/:id/vote", {(request: HTTPRequest, params: Map[String, String] val): HTTPResponse =>
      try
        let post_id = params("id")?
        let headers = recover val Map[String, String] end
        HTTPResponse(200, headers, "Voted on post: " + post_id + "\n")
      else
        let headers = recover val Map[String, String] end
        HTTPResponse(400, headers, "Invalid post ID parameter\n")
      end
    }))

  be connected(conn: TCPConnection tag) =>
    _connections.set(conn)
    _env.out.print("New connection")
    
  be received(conn: TCPConnection tag, data: Array[U8] val) =>
    _env.out.print("Received raw data: " + String.from_array(data))
    try
      let request = _parse_request(data)?
      
      let response = _handle_request(request)
      _env.out.print("Sending response:\n" + response.string())
      conn.write(response.string())
    else
      // Send 400 Bad Request on parsing error
      let headers = recover val Map[String, String] end
      let response = HTTPResponse(400, headers, "Bad Request\n")
      conn.write(response.string())
    end
    
  be closed(conn: TCPConnection tag) =>
    _connections.unset(conn)
    _env.out.print("Connection closed")
  
  fun _parse_request(data: Array[U8] val): HTTPRequest ? =>
    let request_str = String.from_array(data)
    let lines = request_str.split("\r\n")
    
    let request_line = lines(0)?.split(" ")
    let method_str = request_line(0)?
    let path = request_line(1)?
    
    let method = match method_str
    | "GET" => GET
    | "POST" => POST
    | "PUT" => PUT
    | "DELETE" => DELETE
    else
      error
    end
    
    let headers = recover trn Map[String, String] end
    var i: USize = 1
    var found_empty_line = false
    
    while i < lines.size() do
      let line = lines(i)?
      if line == "" then
        found_empty_line = true
        i = i + 1
        break
      end
      
      let header = line.split(": ")
      try
        headers(header(0)?) = header(1)?
      end
      i = i + 1
    end
    
    let body = recover val
      let s = String
      if found_empty_line and (i < lines.size()) then
        var first = true
        while i < lines.size() do
          try
            if not first then
              s.append("\n")
            end
            s.append(lines(i)?)
            first = false
          end
          i = i + 1
        end
      end
      s
    end
    
    HTTPRequest(method, path, consume headers, body)
    
  fun _handle_request(request: HTTPRequest): HTTPResponse =>
    for route in _routes.values() do
      (let matches, let response) = route.matches(request)
      if matches then
        return response
      end
    end
    
    let headers = recover val Map[String, String] end
    HTTPResponse(404, headers, "Not Found\n")


class HTTPServerListener is TCPListenNotify
  let _server: HTTPServer
  let _env: Env
  
  new iso create(server: HTTPServer, env: Env) =>
    _server = server
    _env = env
  
  fun ref listening(listen: TCPListener ref) =>
    try
      (let host, let service) = listen.local_address().name()?
      _env.out.print("Listening on " + host + ":" + service)
    else
      _env.out.print("Listening on unknown address")
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _env.out.print("Failed to listen")

  fun ref closed(listen: TCPListener ref) =>
    _env.out.print("Listener closed")

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    HTTPServerConnection(_server)

class HTTPServerConnection is TCPConnectionNotify
  let _server: HTTPServer
  
  new iso create(server: HTTPServer) =>
    _server = server
  
  fun ref accepted(conn: TCPConnection ref) =>
    _server.connected(conn)
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _server.received(conn, consume data)
    true
  
  fun ref closed(conn: TCPConnection ref) =>
    _server.closed(conn)
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    None

actor Main
  new create(env: Env) =>
    let auth = TCPListenAuth(env.root)
    let http_server = HTTPServer(env, auth)