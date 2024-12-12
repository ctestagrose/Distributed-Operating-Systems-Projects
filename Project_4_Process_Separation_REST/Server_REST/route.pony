use "net"
use "collections"

class val Route
  let method: Method
  let pattern: RoutePattern
  let handler: {(HTTPRequest, Map[String, String] val, TCPConnection tag): HTTPResponse} val

  new val create(method': Method, path: String, 
    handler': {(HTTPRequest, Map[String, String] val, TCPConnection tag): HTTPResponse} val) =>
    method = method'
    pattern = RoutePattern(path)
    handler = handler'

  fun matches(request: HTTPRequest, conn: TCPConnection tag): (Bool, HTTPResponse) =>
    (let is_match, let params) = pattern.matches(request.path)
    if (method is request.method) and is_match then
      (true, handler(request, params, conn))
    else
      (false, HTTPResponse(404, recover val Map[String, String] end, "Not Found\n"))
    end


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
