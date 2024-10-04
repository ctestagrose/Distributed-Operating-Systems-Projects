use "collections"
use "random"
use "time"

class WorkerTimerNotify is TimerNotify
  let _worker: Worker
  let _algorithm: String

  new iso create(worker: Worker, algorithm: String) =>
    _worker = worker
    _algorithm = algorithm

  fun ref apply(timer: Timer, count: U64): Bool =>
    match _algorithm.upper()
    | "GOSSIP" =>
      _worker.send_rumor()
    | "PUSH-SUM" =>
       _worker.send_push_sum()
    end
    true

  fun ref cancel(timer: Timer) =>
    None


actor Worker
  let _env: Env
  let _id: U64
  let _algorithm: String
  var _neighbors: Array[Worker tag] 
  var message_count: U64 = 0
  var rumor_terminated: Bool = false
  var rumor: String = ""
  let _rng: Random ref
  let _coordinator: Coordinator
  var timers: Timers tag = Timers
  var _timer: (Timer tag | None) = None
  var s: F64 = 0.0
  var w: F64 = 0.0
  var last_estimate: F64 = 0.0
  var stable_count: U64 = 0
  var push_sum_terminated: Bool = false
  var converged: Bool = false

  new create(coordinator: Coordinator, env: Env, id: U64, algorithm: String) =>
    _env = env
    _id= id
    _neighbors = Array[Worker tag]
    _rng = Rand(Time.now()._2.u64() + _id)
    _coordinator = coordinator
    _algorithm = algorithm
    let timerIso = Timer(WorkerTimerNotify(this, _algorithm), 10_000, 10_000)
    _timer = timerIso
    timers(consume timerIso) 
    s = _id.f64()
    w = 1.0

  be add_neighbor(neighbor: Worker) =>
    if not _neighbors.contains(neighbor) then
      _neighbors.push(neighbor)
    end

  be receive_rumor(recieved_rumor: String) =>
    if recieved_rumor == "" then return end

    if rumor == "" then
      rumor = recieved_rumor
      _coordinator.worker_received_rumor(_id)
    end

    message_count = message_count + 1

    if (message_count >= 3) and not converged then
      converged = true
      _coordinator.worker_converged(_id)
    end

  be send_rumor() =>
    if (_neighbors.size() > 0) and (rumor_terminated == false) and (rumor != "") then
      try
        let neighbor_index: U64 = _rng.int(_neighbors.size().u64())
        let neighbor = _neighbors(neighbor_index.usize())?
        neighbor.receive_rumor(rumor)
      end
    end

  be receive_push_sum(s_recv: F64, w_recv: F64) =>
    if push_sum_terminated then return end

    s = s + s_recv
    w = w + w_recv
    message_count = message_count + 1

    let new_estimate = s / w
    let diff = (new_estimate - last_estimate).abs()

    if (message_count >= 3) and (diff < 1e-10) then
      stable_count = stable_count + 1
    else
      stable_count = 0
    end

    last_estimate = new_estimate

    if (stable_count > 3) and not converged then
      converged = true
      _coordinator.worker_converged(_id)
    end

  be send_push_sum() =>
    if push_sum_terminated then return end

    if (_neighbors.size() > 0) then
      try
        var s_to_send: F64
        var w_to_send: F64

        if converged then
          s_to_send = 0.0
          w_to_send = 0.0
        else
          let s_half = s / 2.0
          let w_half = w / 2.0
          s = s_half
          w = w_half
          s_to_send = s_half
          w_to_send = w_half
        end

        let neighbor_index: U64 = _rng.int(_neighbors.size().u64())
        let neighbor = _neighbors(neighbor_index.usize())?
        neighbor.receive_push_sum(s_to_send, w_to_send)
      end
    end

  be terminate() =>
    try
      if _timer isnt None then
        let timer = _timer as Timer tag
        timers.cancel(timer)
        _timer = None
      end
    end

  be stop_push_sum() =>
    push_sum_terminated = true
    if _timer isnt None then
      try
        let timer = _timer as Timer tag
        timers.cancel(timer)
        _timer = None
      end
    end
    _coordinator.worker_terminated_sum(_id, last_estimate)

  be stop_gossip() =>
    rumor_terminated = true
    if _timer isnt None then
      try
        let timer = _timer as Timer tag
        timers.cancel(timer)
        _timer = None
      end
    end
    _coordinator.worker_terminated_gossip(_id, rumor)


actor Coordinator
  let _env: Env
  let _numNodes: U64
  let _topology: String
  let _algorithm: String
  var _workers: Array[Worker tag]
  var _workers_received: Array[U64]
  let _begin: U64
  var _terminated_workers: U64 = 0
  var _sum_estimates: F64 = 0.0
  var _converged_workers: U64 = 0
  

  new create(env: Env, numNodes: U64, topology: String, algorithm: String) =>
    _env = env
    _numNodes = numNodes
    _topology = topology
    _algorithm = algorithm
    _workers = Array[Worker tag]
    _workers_received = Array[U64]
    _begin = Time.nanos()

    for i in Range[U64](0, numNodes) do
    let worker = Worker(this, _env, i, _algorithm)
    _workers.push(worker)
    end

    match _topology.upper()
    | "LINE" =>
        setup_line_topology()
    | "FULL" =>
        setup_full_topology()
    | "3D" =>
        setup_3d_grid_topology()
    | "IMPERFECT3D" =>
        setup_imperfect_3d_grid_topology()
    else
      _env.out.print("Unknown topology: " + _topology)
      _env.out.print("Please provide 1 of the Following:\nLine\nFull\n3D\nImperfect3D")
    end

  fun setup_line_topology() =>
    for i in Range[USize](0, _workers.size()) do
      try
        if i > 0 then
          _workers(i)?.add_neighbor(_workers(i - 1)?)
          _workers(i - 1)?.add_neighbor(_workers(i)?)
        end
      end
    end
    _env.out.print("Line topology setup complete.")
    send_command()

  fun setup_full_topology() =>
    for i in Range[USize](0, _workers.size()) do
      for j in Range[USize](0, _workers.size()) do
        try
          if i != j then
            _workers(i)?.add_neighbor(_workers(j)?)
          end
        end
      end
    end
    _env.out.print("Full network topology setup complete.")
    send_command()

fun setup_3d_grid_topology() =>
  let dim = (_workers.size().f64().pow(1.0/3.0)).ceil().usize()
  let grid_size = dim * dim * dim
  for i in Range[USize](0, _workers.size()) do
    try
      let worker = _workers(i)?
      let x = i % dim
      let y = (i / dim) % dim
      let z = (i / (dim * dim)) % dim
      if x > 0 then 
        let neighbor_index = i - 1
        if (neighbor_index >= 0) and (neighbor_index < _workers.size()) then
          worker.add_neighbor(_workers(neighbor_index)?)
        end
      end
      if x < (dim - 1) then 
        let neighbor_index = i + 1
        if (neighbor_index >= 0) and (neighbor_index < _workers.size()) then
          worker.add_neighbor(_workers(neighbor_index)?)
        end
      end
      if y > 0 then
        let neighbor_index = i - dim
        if (neighbor_index >= 0) and (neighbor_index < _workers.size()) then
            worker.add_neighbor(_workers(neighbor_index)?)
          end
        end
      if y < (dim - 1) then
        let neighbor_index = i + dim
        if (neighbor_index >= 0) and (neighbor_index < _workers.size()) then
          worker.add_neighbor(_workers(neighbor_index)?)
        end
      end
      if z > 0 then
        let neighbor_index = i - (dim * dim)
        if (neighbor_index >= 0) and (neighbor_index < _workers.size()) then
          worker.add_neighbor(_workers(neighbor_index)?)
        end
      end
      if z < (dim - 1) then
        let neighbor_index = i + (dim * dim)
        if (neighbor_index >= 0) and (neighbor_index < _workers.size()) then
          worker.add_neighbor(_workers(neighbor_index)?)
        end
      end
    end
  end
  _env.out.print("3D Grid topology setup complete.")
  send_command()


  fun setup_imperfect_3d_grid_topology() =>
    let dim = (_workers.size().f64().pow(1/3).ceil()).usize()
    for i in Range[USize](0, _workers.size()) do
      try
        let worker = _workers(i)?
        let x = i % dim
        let y = (i / dim) % dim
        let z = i / (dim * dim)
        if x > 0 then 
          worker.add_neighbor(_workers(i - 1)?) 
        end
        if x < (dim - 1) then 
          worker.add_neighbor(_workers(i + 1)?) 
        end
        if y > 0 then
          worker.add_neighbor(_workers(i - dim)?) 
        end
        if y < (dim - 1) then 
          worker.add_neighbor(_workers(i + dim)?) 
        end
        if z > 0 then 
          worker.add_neighbor(_workers(i - (dim * dim))?) 
        end
        if z < (dim - 1) then 
          worker.add_neighbor(_workers(i + (dim * dim))?) 
        end
      end
    end

    let rng = Rand(Time.now()._2.u64())
    
    for i in Range[USize](0, _workers.size()) do
      try
        let worker = _workers(i)?
        let num = rng.int(_workers.size().u64())
        if num != i.u64() then
          worker.add_neighbor(_workers(num.usize())?)
        end
      end
    end
    _env.out.print("Imperfect 3D Grid topology setup complete.")

    send_command()

  fun done() =>
    let ending = Time.nanos()
    let elapsed_time = (ending - _begin).f64() / 1000000000.0
    _env.out.print("Time to converge: " + elapsed_time.string() + " sec")
    _env.out.print("Terminating workers...")
    for i in Range[USize](0, _workers.size()) do
      try
        _workers(i)?.terminate()
      end
    end
    _env.out.print("All workers terminated. ")

  be worker_received_rumor(worker_id: U64) =>
    _workers_received.push(worker_id)
    // _env.out.print("Worker "+worker_id.string()+" has received rumor")
    if _workers_received.size().u64() == _numNodes.u64() then
      _env.out.print("All workers have received the rumor.")
      done()
    end

  fun send_command() =>
    match _algorithm.upper()
    | "GOSSIP" =>
        try
          let rng = Rand(Time.now()._2.u64())
          let start_worker_index: U64 = rng.int(_workers.size().u64())
          let start_worker = _workers(start_worker_index.usize())?
          _env.out.print("Starting with worker "+start_worker_index.string())
          start_worker.receive_rumor("Here")
        end
    | "PUSH-SUM" =>
        try
          let rng = Rand(Time.now()._2.u64())
          let start_worker_index: U64 = rng.int(_workers.size().u64())
          let start_worker = _workers(start_worker_index.usize())?
          _env.out.print("Starting with worker "+start_worker_index.string())
          start_worker.send_push_sum()
        end
    else
      _env.out.print("Unknown algorithm: " + _algorithm)
      return
    end

  be worker_terminated_sum(worker_id: U64, estimate: F64) =>
    _terminated_workers = _terminated_workers + 1
    _sum_estimates = _sum_estimates + estimate
    // _env.out.print("Worker " + worker_id.string() + " has terminated with estimate " + estimate.string())

    if _terminated_workers == _numNodes then
      _env.out.print("All workers have terminated.")
      _env.out.print("Final estimate of the sum is: " + (_sum_estimates / _numNodes.f64()).string())
      done()
    end

  be worker_terminated_gossip(worker_id: U64, rumor: String) =>
    _terminated_workers = _terminated_workers + 1
    // _env.out.print("Worker " + worker_id.string() + " has terminated with rumor " + rumor)

    if _terminated_workers == _numNodes then
      _env.out.print("All workers have terminated.")
      done()
    end

  be worker_converged(worker_id: U64) =>
    _converged_workers = _converged_workers + 1
    // _env.out.print("Worker " + worker_id.string() + " has locally converged.")

    if _converged_workers == _numNodes then
      _env.out.print("All workers have locally converged.")
      match _algorithm.upper()
      | "GOSSIP" =>
            for worker in _workers.values() do
              worker.stop_gossip()
            end
      | "PUSH-SUM" =>
            for worker in _workers.values() do
              worker.stop_push_sum()
            end
      end
    end
      

actor Main
  var valid_topologies: Array[String] = ["LINE"; "FULL"; "3D"; "IMPERFECT3D"]
  var valid_algorithms: Array[String] = ["GOSSIP"; "PUSH-SUM"]
  new create(env: Env) =>
    if env.args.size() != 4 then
      env.out.print("Please provide 3 inputs: <numNodes> <topology> <algorithm>")
      return
    end

    try
      let numNodes = env.args(1)?.u64()?
      let topology = env.args(2)?.upper().trim()
      let algorithm = env.args(3)?.upper().trim()

      var check_top: Bool = false
      var check_algo: Bool = false
      for i in Range[USize](0, valid_topologies.size()) do
          if valid_topologies(i)? == topology then
            check_top = true
          end
      end
      for i in Range[USize](0, valid_algorithms.size()) do
          if valid_algorithms(i)? == algorithm then
            check_algo = true
          end
      end

      if not check_top then
        env.out.print(topology + " topology not valid")
        env.out.print("Valid Topologies: Line, Full, 3D, Imperfect3D")
      else if not check_algo then
        env.out.print("Algorithm " + algorithm + " not valid")
        env.out.print("Valid Algorithms: Gossip, Push-Sum")
      else
        let _ = Coordinator(env, numNodes, topology, algorithm)
      end
      end
    else
      env.out.print("Invalid arguments provided.")
      env.out.print("Please provide 3 inputs: <numNodes> <topology> <algorithm>")
      env.out.print("Valid Topologies: Line, Full, 3D, Imperfect3D")
      env.out.print("Valid Algorithms: Gossip, Push-Sum")
    end
