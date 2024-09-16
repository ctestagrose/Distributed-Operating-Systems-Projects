use "net"
use "time"

actor Worker
  let _boss: Main
  let _start: U64
  let _end_val: U64
  let _seqLength: U64
  let _ultimateEnd: U64
  let _conn: TCPConnection
  var _start_time: (I64, I64) = (0, 0)

  new create(boss: Main, start: U64, end_val: U64, seqLength: U64, ultimateEnd: U64, conn: TCPConnection) =>
    _start_time = Time.now()
    _boss = boss
    _start = start
    _end_val = end_val
    _seqLength = seqLength
    _ultimateEnd = ultimateEnd
    _conn = conn
    run()
    checkin()

   be run() =>
    var current_val: U64 = _start
    while current_val <= _end_val do
      if (current_val + (_seqLength - 1)) > (_ultimateEnd+1) then
        break
      end
      let sum_sq = sum_of_squares(current_val, _seqLength)
      
      // Check if sum of squares is a perfect square
      if is_perfect_square(sum_sq) then
        _boss.result(current_val, sum_sq, _conn)
      end
      
      // Move to the next starting number in the worker's range
      current_val = current_val + 1
    end

  be checkin() =>
    let end_time: (I64, I64) = Time.now()  // Capture end time
    let elapsed_seconds = end_time._1 - _start_time._1  // Subtract seconds
    let elapsed_nanoseconds = end_time._2 - _start_time._2  // Subtract nanoseconds
    let elapsed_total_nanoseconds: I64 = (elapsed_seconds * 1_000_000_000) + elapsed_nanoseconds
    _boss.rollcall(_conn, elapsed_total_nanoseconds)

  fun sum_of_squares(start: U64, k: U64): U64 =>
    // Sum of squares function
    var sum: U64 = 0
    var i: U64 = start
    var count: U64 = 0
    while count < k do
      sum = sum + (i * i)
      i = i + 1
      count = count + 1
    end
    sum

  fun is_perfect_square(n: U64): Bool =>
    // Checks for perfect square
    let sqrt_n = binary_search_sqrt(n)
    (sqrt_n * sqrt_n) == n

  fun binary_search_sqrt(n: U64): U64 =>
    // Binary search
    if n < 2 then
      n
    else
      var low: U64 = 1
      var high: U64 = n
      var mid: U64 = 0
      while low <= high do
        mid = (low + high) / 2
        let square = mid * mid
        if square == n then
          return mid
        elseif square < n then
          low = mid + 1
        else
          high = mid - 1
        end
      end
      high
    end

actor Main
  let _env: Env
  var _total_sum: U64 = 0
  var _workers: U64 = 0
  var _results_received: U64 = 0
  var _start_time:(I64, I64) = (0, 0)
  var _total_elapsed_time: I64 = 0

  new create(env: Env) =>
    _env = env
    env.out.print("Starting, trying to bind to port 8999.")
    TCPListener(TCPListenAuth(env.root),
      recover MyTCPListenNotify(env, this) end, "192.168.1.215", "8999")
    env.out.print("Successfully bound to port 8999.")

  be assign_work(endValue: U64, seqLength: U64, numberWorkers: U64, conn: TCPConnection) =>
    _start_time = Time.now()
    _total_elapsed_time = 0
    let actualWorkers: U64 = if endValue < numberWorkers then endValue else numberWorkers end
    let rangeSize: U64 = endValue / actualWorkers
    var start: U64 = 1
    var count: U64 = 0
    var end_range: U64 = 0
    _results_received = 0
    _workers = actualWorkers
    let client_conn = conn

    while count < actualWorkers do
      if count == (actualWorkers - 1) then
        end_range = endValue
      else
        end_range = start + (rangeSize - 1)
      end
      let worker = Worker(this, start, end_range, seqLength, endValue, conn)
      // _env.out.print("Assigning range: " + start.string() + " to " + end_range.string())
      start = end_range + 1
      count = count + 1
    end

  be result(start: U64, sum_sq: U64, conn: TCPConnection) =>
    _total_sum = _total_sum + sum_sq
    conn.write("Perfect square found with start: " + start.string() + " Sequence sum: " + sum_sq.string() + "\n")
  
  be rollcall(conn: TCPConnection, worker_time: I64) =>
    _results_received = _results_received + 1
    _total_elapsed_time = _total_elapsed_time + worker_time

    if _results_received == _workers then
      let end_time: (I64, I64) = Time.now()

      // Calculate the real elapsed time (wall-clock time)
      let elapsed_seconds = end_time._1 - _start_time._1  // Subtract seconds
      let elapsed_nanoseconds = end_time._2 - _start_time._2  // Subtract nanoseconds
      let elapsed_total_nanoseconds: I64 = (elapsed_seconds * 1_000_000_000) + elapsed_nanoseconds

      let elapsed_seconds_final: F64 = elapsed_total_nanoseconds.f64() / 1_000_000_000.0
      let elapsed_milliseconds: F64 = elapsed_total_nanoseconds.f64() / 1_000_000.0
      let elapsed_microseconds: F64 = elapsed_total_nanoseconds.f64() / 1_000.0

      // Calculate the total worker CPU time (summed times of all workers)
      let elapsed_seconds_workers: F64 = _total_elapsed_time.f64() / 1_000_000_000.0
      let elapsed_milliseconds_workers: F64 = _total_elapsed_time.f64() / 1_000_000.0
      let elapsed_microseconds_workers: F64 = _total_elapsed_time.f64() / 1_000.0

      // Output the total wall-clock time and worker CPU times
      _env.out.print("Real elapsed time (sec): " + elapsed_seconds_final.string() + " seconds.")
      _env.out.print("Real elapsed time (ms): " + elapsed_milliseconds.string() + " milliseconds.")
      _env.out.print("Real elapsed time (us): " + elapsed_microseconds.string() + " microseconds.")

      _env.out.print("Total worker CPU time (sec): " + elapsed_seconds_workers.string() + " seconds.")
      _env.out.print("Total worker CPU time (ms): " + elapsed_milliseconds_workers.string() + " milliseconds.")
      _env.out.print("Total worker CPU time (us): " + elapsed_microseconds_workers.string() + " microseconds.")

      conn.write("All workers completed, closing connection...")
      conn.dispose()
    end


class MyTCPConnectionNotify is TCPConnectionNotify
  let _env: Env
  let _boss: Main

  new iso create(env: Env, boss: Main) =>
    _env = env
    _boss = boss

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize): Bool =>
    
    // _env.out.print("Data received from client.")
    let task = String.from_array(consume data)
    let parts = task.split(" ")

    if parts.size() < 2 then
      conn.write("Invalid input. Expected end value and seqLength.")
      return true
    end

    try
      let end_val: U64 = parts(0)?.u64()?    // The end value for the range
      let seqLength: U64 = parts(1)?.u64()?  // The sequence length

      let numberWorkers: U64 = 6400
      
      // _env.out.print("Calculated workers: " + numberWorkers.string())
      _boss.assign_work(end_val, seqLength, numberWorkers, conn)

    else
      _env.out.print("Error processing input.")
    end

    true

  fun ref connected(conn: TCPConnection ref) =>
    _env.out.print("Client connected.")

  fun ref connect_failed(conn: TCPConnection ref) =>
    _env.out.print("Connection to Client failed")

// TCPListener Notify class responsible for creating new connections
class MyTCPListenNotify is TCPListenNotify
  let _env: Env
  let _boss: Main
  var _host: String = ""
  var _service: String = ""

  new create(env: Env, boss: Main) =>
    _env = env
    _boss = boss

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    _env.out.print("Connection received, setting up connection notify handler.")
    recover MyTCPConnectionNotify(_env, _boss) end

  fun ref listening(listen: TCPListener ref) =>
    try
      (_host, _service) = listen.local_address().name()?
      _env.out.print("listening on " + _host + ":" + _service)
    else
      _env.out.print("couldn't get local address")
      listen.close()
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _env.out.print(" Server failed to start listening.")