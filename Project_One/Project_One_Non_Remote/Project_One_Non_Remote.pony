use "time"
use "net"

// Worker actor
actor Worker
  let _boss: Boss
  let _start: U64
  let _end_val: U64
  let _seqLength: U64
  let _ultimateEnd: U64

  new create(boss: Boss, start: U64, end_val: U64, seqLength: U64, ultimateEnd: U64) =>
    _boss = boss
    _start = start
    _end_val = end_val
    _seqLength = seqLength
    _ultimateEnd = ultimateEnd
    run()

  be run() =>
    var current_val: U64 = _start
    while current_val <= _end_val do
      if (current_val + (_seqLength - 1)) > (_ultimateEnd+1) then
        break
      end
      let sum_sq = sum_of_squares(current_val, _seqLength)
      
      // Check if sum of squares is a perfect square
      if is_perfect_square(sum_sq) then
        _boss.result(current_val, sum_sq)
      end
      
      // Move to the next starting number in the worker's range
      current_val = current_val + 1
    end

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

// Boss actor
actor Boss
  let _env: Env 

  new create(env: Env, numberWorkers: U64, endValue: U64, seqLength: U64) =>
    _env = env
    assign_work(numberWorkers, endValue, seqLength)

  // Boss will print the results
  be result(start: U64, sum_sq: U64) =>
    // _env.out.print("Perfect square found with start: " + start.string() +
    //                " Sequence sum: " + sum_sq.string())
    _env.out.print(start.string())

  be assign_work(numberWorkers: U64, endValue: U64, seqLength: U64) =>
    let rangeSize: U64 = endValue / numberWorkers
    var start: U64 = 1
    var count: U64 = 0
    var end_range: U64 = 0

    while count < numberWorkers do
      if count == (numberWorkers - 1) then
        end_range = endValue
      else
        end_range = start + rangeSize
      end
      let worker = Worker(this, start, end_range, seqLength, endValue)
      start = end_range + 1
      count = count + 1
    end


// Main actor
actor Main
  new create(env: Env) =>
    if env.args.size() != 3 then
      env.out.print("Please provide exactly 2 values as input.")
      return
    end

    try
      let endValue: U64 = env.args(1)?.u64()?
      let seqLength: U64 = env.args(2)?.u64()?

      let numberWorkers: U64 = 64000

      // env.out.print("Number of Workers: " + numberWorkers.string())
      let boss = Boss(env, numberWorkers, endValue, seqLength)
    end