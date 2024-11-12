use "net"
use "collections"
use "../Engine"

interface tag ServerNotify
  be connected(conn: TCPConnection tag)
  be received(conn: TCPConnection tag, data: Array[U8] val)
  be closed(conn: TCPConnection tag)
  be connect_failed(conn: TCPConnection tag)

class ServerListener is TCPListenNotify
  let _server: ServerNotify
  let _env: Env

  new iso create(server: ServerNotify, env: Env) =>
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
    ServerConnectionNotify(_server, _env)

class ServerConnectionNotify is TCPConnectionNotify
  let _server: ServerNotify
  let _env: Env
  
  new iso create(server: ServerNotify, env: Env) =>
    _server = server
    _env = env
    
  fun ref connected(conn: TCPConnection ref) =>
    _server.connected(conn)
    
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _server.received(conn, consume data)
    true
    
  fun ref closed(conn: TCPConnection ref) =>
    _server.closed(conn)
    
  fun ref connect_failed(conn: TCPConnection ref) =>
    _server.connect_failed(conn)