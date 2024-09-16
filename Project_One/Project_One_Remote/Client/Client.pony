use "net"


actor Main
  let _env: Env

  new create(env: Env) =>
    _env = env
    request_input()

  be request_input() =>
    if _env.args.size() != 3 then
      _env.out.print("Please provide exactly 2 values as input.")
      return
    end
    try
      let endValue: String = _env.args(1)?.string()
      let seqLength: String = _env.args(2)?.string()
      
      let task = consume endValue + " " + consume seqLength


      connect_to_worker(consume task)
    end

  be connect_to_worker(task: String) =>
    _env.out.print("Attempting to connect to worker...")
    TCPConnection(TCPConnectAuth(_env.root),
      recover MyTCPConnectionNotify(_env, task) end, "192.168.1.215", "8999")
    _env.out.print("Connection initiated, waiting for response...")

class MyTCPConnectionNotify is TCPConnectionNotify
  let _env: Env
  let _task: String

  new create(env: Env, task: String) =>
    _env = env
    _task = task

  fun ref connected(conn: TCPConnection ref) =>
    _env.out.print("Successfully connected to worker, sending task: " + _task)
    // Send the task to the worker
    conn.write(_task)
    _env.out.print(_task)
    _env.out.print("Task sent successfully.")

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool =>
    // Receive and process response from worker
    let result = String.from_array(consume data)
    _env.out.print(result)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _env.out.print("Connection to worker failed. Is the worker running?")

  fun ref closed(conn: TCPConnection ref) =>
    _env.out.print("Connection closed.")
