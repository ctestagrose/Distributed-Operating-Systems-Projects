use "net"

interface tag ClientNotify
  be connected()
  be received(data: Array[U8] val)
  be closed()
  be connect_failed()

class ClientConnectionNotify is TCPConnectionNotify
  let _client: ClientNotify
  let _env: Env
  
  new iso create(client: ClientNotify, env: Env) =>
    _client = client
    _env = env
    
  fun ref connected(conn: TCPConnection ref) =>
    _client.connected()
    
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    _client.received(consume data)
    true
    
  fun ref closed(conn: TCPConnection ref) =>
    _client.closed()
    
  fun ref connect_failed(conn: TCPConnection ref) =>
    _client.connect_failed()