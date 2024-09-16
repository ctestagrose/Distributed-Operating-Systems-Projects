use "net"

// Main Actor
actor Main
  let _env: Env

  new create(env: Env) =>
    _env = env
    request_input()

  be request_input() =>
    if _env.args.size() != 4 then
      _env.out.print("Please provide exactly end value, sequence length, and server ip address as input.")
      return
    end
    try
      let endValue: String = _env.args(1)?.string()
      let seqLength: String = _env.args(2)?.string()
      let ip_address: String = _env.args(3)?.string()
      
      let task = consume endValue + " " + consume seqLength


      connect_to_worker(consume task, consume ip_address)
    end

  // Attempt to Connect to the Server
  be connect_to_worker(task: String, ip_address: String) =>
    _env.out.print("Attempting to connect to server...")
    TCPConnection(TCPConnectAuth(_env.root),
      recover MyTCPConnectionNotify(_env, task) end, ip_address, "8999")
    _env.out.print("Connection initiated, waiting for response...")

// Handle connections
class MyTCPConnectionNotify is TCPConnectionNotify
  let _env: Env
  let _task: String

  new create(env: Env, task: String) =>
    _env = env
    _task = task

  // Connect and send task
  fun ref connected(conn: TCPConnection ref) =>
    _env.out.print("Successfully connected to server, sending task: " + _task)
    conn.write(_task)
    _env.out.print("Task sent successfully.")

  // Print result from server to user
  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool =>
    let result = String.from_array(consume data)
    _env.out.print(result)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _env.out.print("Connection to server failed. Is the server running?")

  fun ref closed(conn: TCPConnection ref) =>
    _env.out.print("Connection closed.")
