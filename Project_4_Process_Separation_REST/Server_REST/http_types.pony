use "collections"

primitive HTTPStatus
  fun text(code: U16): String =>
    match code
    | 200 => "OK"
    | 201 => "Created"
    | 204 => "No Content"
    | 400 => "Bad Request"
    | 401 => "Unauthorized"
    | 404 => "Not Found"
    | 405 => "Method Not Allowed"
    | 500 => "Internal Server Error"
    else
      "Unknown"
    end


class val HTTPRequest
  let method: Method
  let path: String
  let headers: Map[String, String] val
  let body: String
  
  new val create(method': Method, path': String, 
    headers': Map[String, String] val, body': String) =>
    method = method'
    path = path'
    headers = headers'
    body = body'


class val HTTPResponse
  let status: U16
  let headers: Map[String, String] val
  let body: String

  new val create(status': U16, headers': Map[String, String] val, body': String) =>
    status = status'
    headers = headers'
    body = body'

  fun string(): String =>
    let response = recover iso String end
    response.append("HTTP/1.1 " + status.string() + " " + HTTPStatus.text(status) + "\r\n")
    response.append("Connection: close\r\n")

    for (name, value) in headers.pairs() do
      response.append(name + ": " + value + "\r\n") 
    end

    response.append("Content-Length: " + body.size().string() + "\r\n")

    if not headers.contains("Content-Type") then
      response.append("Content-Type: text/plain\r\n")
    end

    response.append("\r\n")
    response.append(body)

    consume response
