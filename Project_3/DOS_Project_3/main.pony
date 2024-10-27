use "collections"
use "random"
use "time"


actor Main
  new create(env: Env) =>
    try
      let args = env.args
      let num_nodes = args(1)?.u64()?
      let num_requests = args(2)?.u64()?
      
      let chord_system = ChordSystem(num_nodes, num_requests, env)
      chord_system.run()
    else
      env.out.print("Usage: ./implementation numNodes numRequests")
    end

actor ChordSystem
  let _env: Env
  let _nodes: Array[(Node, U64, U64, U64)]
  let _num_nodes: U64
  let _num_requests: U64
  var _total_hops: U64 = 0
  var _completed_requests: U64 = 0
  let _timers: Timers = Timers
  var _start_time: U64 = 0
  var _end_time: U64 = 0

  new create(num_nodes: U64, num_requests: U64, env: Env) =>
    _env = env
    _num_nodes = num_nodes
    _num_requests = num_requests
    _nodes = Array[(Node, U64, U64, U64)](num_nodes.usize())

  fun create_random_node_ids(num_nodes: U64, max_id: U64): Array[U64] =>
    let ids = Set[U64]()
    let rng = Rand(Time.now()._2.u64())
    while ids.size() < num_nodes.usize() do
      let id = rng.u64() % max_id
      ids.set(id)
    end
    let id_array = Array[U64](num_nodes.usize())
    for i in ids.values() do
      id_array.push(i)
    end
    id_array

  be run() =>
    _env.out.print("\nStarting Chord network... ")
    let setup_time_start = Time.nanos()
    let m = _calculate_m(_num_nodes)
    let key_space_size = pow(2, m)
    let node_ids = create_random_node_ids(_num_nodes, key_space_size)
    let sorted_node_ids = Sort[Array[U64], U64](node_ids)

    let node_count = node_ids.size()
    var count: U64 = 0
    for i in node_ids.values() do
      let node = Node(i.u64(), key_space_size, m, this, _env)
      let successor_index = (count + 1) % node_count.u64()
      let predecessor_index = ((count + node_count.u64()) - 1) % node_count.u64()
      count = count + 1
      _nodes.push((node, i.u64(), successor_index.u64(), predecessor_index.u64()))
    end

    // Connect nodes in the Chord ring
    for i in Range(0, node_count) do
      try
        let current_node = _nodes(i)?._1
        let current_id = _nodes(i)?._2
        let successor_index = (i + 1) % node_count
        let predecessor_index = ((i + node_count) - 1) % node_count
        let successor_node = _nodes(successor_index)?._1
        let successor_id = _nodes(successor_index)?._2
        let predecessor_node = _nodes(predecessor_index)?._1
        let predecessor_id = _nodes(predecessor_index)?._2
        current_node.set_successor(successor_node, successor_id)
        current_node.set_predecessor(predecessor_node, predecessor_id)
      end
    end

    let setup_time_end = Time.nanos()
    let set_up_duration = (setup_time_end - setup_time_start).f64() / 1e9
    // _env.out.print("Setup Complete. Time Taken: " + set_up_duration.string() + " seconds\n")


    // _env.out.print("Initializing Finger Tables... ")
    let finger_time_start = Time.nanos()

    for collection in _nodes.values() do
      let node = collection._1
      let node_id = collection._2

      for i in Range(0, m.usize()) do
        let start = (node_id + pow(2, i.u64())) % key_space_size
        try
          var succ_node: Node = _nodes(0)?._1
          for other_collection in _nodes.values() do
            let other_node_id = other_collection._2
            if (other_node_id >= start) then
              succ_node = other_collection._1
              break
            end
          end
        node.initialize_finger_table(succ_node, start)
        end
      end
    end

    let finger_time_end = Time.nanos()
    let finger_duration = (finger_time_end - finger_time_start).f64() / 1e9
    // _env.out.print("Finger Table Initalization Complete. Time Taken: " + finger_duration.string() + " seconds\n")


    _env.out.print("Nodes sending messages... ")
    _start_time = Time.nanos()
    for collection in _nodes.values() do
      let node = collection._1
      node.start_requests(_num_requests)
    end


  be report_hops(hops: U64) =>
    _total_hops = _total_hops + hops
    _completed_requests = _completed_requests + 1
    if _completed_requests == (_num_nodes * _num_requests) then
      _end_time = Time.nanos()
      let duration = (_end_time - _start_time).f64() / 1e9
      // _env.out.print("Total time taken by nodes to send messages: " + duration.string() + " seconds")
      let avg_hops = _total_hops.f64() / _completed_requests.f64()
      _env.out.print("Average number of hops: " + avg_hops.string()+"\n")
      _env.exitcode(0)
    end

  fun _calculate_m(num_nodes: U64): U64 =>
    var temp = num_nodes - 1
    var m: U64 = 0
    while temp > 0 do
        temp = temp >> 1
        m = m + 1
    end
    m

  fun pow(base: U64, exp: U64): U64 =>
    let r: U64 = if exp == 0 then
      1
    elseif (exp % 2) == 0 then
        let t = pow(base, exp / 2)
        t * t  
      else
        base * pow(base, exp - 1)
      end
    r

actor Node
  let _env: Env
  let _id: U64
  let _num_nodes: U64
  var _m: U64
  var _successor: Node = this
  var _successor_id: U64 = 0
  var _predecessor: Node = this
  var _predecessor_id: U64 = 0
  var _finger_table: Array[(Node, U64)] = Array[(Node, U64)]
  let _data: Map[U64, String] = Map[U64, String]
  let _system: ChordSystem
  let _timers: Timers = Timers

  new create(id: U64, num_nodes: U64, m: U64, system: ChordSystem, env: Env) =>
    _env = env
    _id = id
    _m = m
    _num_nodes = num_nodes
    _system = system
    _finger_table = Array[(Node, U64)](_m.usize())

  fun hash(): USize =>
    _id.hash() xor _num_nodes.hash()

  fun string(): String =>
    _id.string()

  be set_successor(node: Node, node_id: U64) =>
    _successor = node
    _successor_id = node_id

  be set_predecessor(node: Node, node_id: U64) =>
    _predecessor = node
    _predecessor_id = node_id


  be initialize_finger_table(node: Node, start: U64) =>
    // _env.out.print(_id.string()+" "+start.string())
    _finger_table.push((node, start))

  be update_finger_table(n: U64, i: U64) =>
    try
      let start = (_id + pow(2, i)) % _num_nodes
      if between(_id, start, _successor_id, _num_nodes) then  
        _finger_table(i.usize())? = (_successor, start)
        match _predecessor 
        | let pred: Node => pred.update_finger_table(n, i)
        end
      else
        match _finger_table(i.usize())?._1 
        | let node: Node => node.update_finger_table(n, i)
        end
      end
    end


  be start_requests(num_requests: U64) =>
    send_request(num_requests)

be send_request(remaining: U64) =>
  if remaining > 0 then
    let rng = Rand(Time.now()._2.u64() + _id)
    let target_key = rng.u64() % pow(2, _m)
    lookup(target_key, 0)
    
    // Generate a random delay between 10ms and 1000ms (1 second)
    let random_delay: U64 = (rng.u64() % 100_000) + 10_000 // 10_000_000 ns = 10 ms, 1_000_000_000 ns = 1 s
    
    // Schedule the next request after the random delay
    let timer = Timer(
      object iso is TimerNotify
        let _node: Node = this
        let _rem: U64 = remaining - 1

        fun ref apply(timer: Timer, count: U64): Bool =>
          _node.send_request(_rem)
          false

        fun ref cancel(timer: Timer) =>
          None
      end,
      // 1_000_000_000 
      random_delay
    )
    _timers(consume timer)
  end

  fun find_closest_preceding_node(key: U64): Node =>
      for i in Range(_m.usize() - 1, -1, -1) do
        try
          (let node: Node, let value: U64) = _finger_table(i)?
          if between(_id, value, key, pow(2, _m)) then
            return node
          end
        end
      end
      _successor

  be lookup(key: U64, hops: U64) =>
    // _env.out.print("Node " + _id.string() + " looking up key " + key.string() + " (hops: " + hops.string() + ")")
    
    if (key == _id) or between(_predecessor_id, key, _id, pow(2, _m)) then
      // _env.out.print("Key " + key.string() + " found at node " + _id.string() + " in " + hops.string() + " hops")
      _system.report_hops(hops)
    elseif between(_id, key, _successor_id, pow(2, _m)) or (key == _successor_id) then
      _successor.lookup(key, hops + 1)
    else
      let closest_preceding_node = find_closest_preceding_node(key)
      if closest_preceding_node is this then
        // _env.out.print("Error: Lookup failed for key " + key.string() + " at node " + _id.string())
        _system.report_hops(hops)
      else
        closest_preceding_node.lookup(key, hops + 1)
      end
    end
    
    if hops > _m then
      // _env.out.print("Warning: Lookup exceeded maximum expected hops for key " + key.string())
      _system.report_hops(hops)
    end


  fun between(start: U64, key: U64, ending: U64, modulus: U64): Bool =>
    if start < ending then
      (key > start) and (key <= ending)
    elseif start > ending then
      (key > start) or (key <= ending)
    else
      key != start
    end

   fun pow(base: U64, exp: U64): U64 =>
      let r: U64 = if exp == 0 then
        1
      elseif (exp % 2) == 0 then
          let t = pow(base, exp / 2)
          t * t  
        else
          base * pow(base, exp - 1)
        end
      r