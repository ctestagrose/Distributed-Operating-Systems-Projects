use "collections"
use "random"
use "time"
use "lib:c" if not windows
use "lib:libssl-32" if windows
use "lib:libcrypto-32" if windows
use "crypto"

use @pow[F64](base: F64, exp: F64)

primitive Math
  fun pow(base: U64, exp: U64): U64 =>
    let result = @pow(base.f64(), exp.f64())
    result.u64()

primitive ConsistentHash
  fun apply(key: String val, m: U64): U64 =>
    let digest = SHA256(key)
    let hash_value: U64 = _bytes_to_u64(digest)
    hash_value % Math.pow(2, m)

  fun hash_node(address: String val, port: String val, m: U64): U64 =>
    let node_key = recover val address + ":" + port end
    apply(node_key, m)

  fun _bytes_to_u64(bytes: Array[U8] val): U64 =>
    var result: U64 = 0
    try
      for i in Range(0, 8) do
        result = (result << 8) or bytes(i)?.u64()
      end
    end
    result

primitive AddressGenerator
  fun apply(num_nodes: U64, env: Env): Array[String val] val =>
    let addresses = recover Array[String val](num_nodes.usize()) end
    let used_addresses = Set[String]
    let rng = Rand(Time.now()._2.u64())

    for i in Range(0, num_nodes.usize()) do
      var address = ""
      repeat
        // fake ipv4 and ports... this is just a simulation
        let ip2: U64 = rng.int(255)
        let ip3: U64 = rng.int(255)
        let ip4: U64 = rng.int(254)
        let port: U64 = rng.int(65535)
        address = recover val ip2.string() + "." + ip3.string() + "." + 
                              ip4.string() + ":" + port.string() end
      until not used_addresses.contains(address) end

      used_addresses.set(address)
      addresses.push(address)
      env.out.print("Generated address: " + address)
    end

    consume addresses

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
  let _node_addresses: Array[String val] val

  new create(num_nodes: U64, num_requests: U64, env: Env) =>
    _env = env
    _num_nodes = num_nodes
    _num_requests = num_requests
    _nodes = Array[(Node, U64, U64, U64)](num_nodes.usize())
    _node_addresses = AddressGenerator(num_nodes, env)

  fun create_consistent_node_ids(num_nodes: U64, m: U64): Array[U64] =>
    let ids = Array[U64](num_nodes.usize())
    for address in _node_addresses.values() do
      try
        let parts = address.split(":")
        let node_addr = parts(0)?
        let port = parts(1)?
        let node_id = ConsistentHash.hash_node(node_addr, port, m)
        ids.push(node_id)
      end
    end
    Sort[Array[U64], U64](ids)

  be run() =>
    _env.out.print("\nStarting Chord network... ")
    let setup_time_start = Time.nanos()
    let m = _calculate_m(_num_nodes)
    let key_space_size = Math.pow(2, m)
    // _env.out.print("Key Space Size: "+key_space_size.string())
    let node_ids = create_consistent_node_ids(_num_nodes, m)
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
        let start = (node_id + Math.pow(2, i.u64())) % key_space_size
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
    let base_m = _log2(num_nodes)
    base_m + 10 

  fun _log2(n: U64): U64 =>
    var temp = n - 1
    var m: U64 = 0
    while temp > 0 do
      temp = temp >> 1
      m = m + 1
    end
    m


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
    _finger_table.push((node, start))

  be update_finger_table(n: U64, i: U64) =>
    try
      let start = (_id + Math.pow(2, i)) % _num_nodes
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
      let target_key = rng.u64() % Math.pow(2, _m)
      lookup(target_key, 0)

      let random_delay: U64 = (rng.u64() % 100_000) + 10_000
      
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
          if between(_id, value, key, Math.pow(2, _m)) then
            return node
          end
        end
      end
      this

  be lookup(key: U64, hops: U64) =>
    // _env.out.print("Node " + _id.string() + " looking up key " + key.string() + " (hops: " + hops.string() + ")")
    
    if (key == _id) or between(_predecessor_id, key, _id, Math.pow(2, _m)) then
      // _env.out.print("Key " + key.string() + " found at node " + _id.string() + " in " + hops.string() + " hops")
      _system.report_hops(hops)
    elseif between(_id, key, _successor_id, Math.pow(2, _m)) or (key == _successor_id) then
      _successor.lookup(key, hops + 1)
    else
      let closest_preceding_node = find_closest_preceding_node(key)
      if closest_preceding_node is this then
        _successor.lookup(key, hops + 1)
      else
        closest_preceding_node.lookup(key, hops + 1)
      end
    end
    
    if hops > _m then
      _system.report_hops(hops)
    end


  fun between(start: U64, key: U64, ending: U64, modulus: U64): Bool =>
    if start < ending then
      (key > start) and (key <= ending)
    elseif start > ending then
      (key > start) or (key <= ending)
    else
      false 
    end


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
