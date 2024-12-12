use "net"
use "collections"

class MenuInputNotify is InputNotify
  let _client: RedditRESTClient
  let _buffer: String ref
  let _env: Env

  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _buffer = String
    _env = env

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data)
    for c in input.values() do
      if (c.u8() == 8) or (c.u8() == 127) then
        if _buffer.size() > 0 then
          _buffer.truncate(_buffer.size() - 1)
          _env.out.write(recover val [8; 32; 8] end)
        end
      else
        if (c == 10) or (c == 13) then
          let choice = _buffer.clone().>trim()
          if choice != "" then
            _env.out.write(recover val [c.u8()] end)
            _client.handle_menu_choice(choice)
          end
          _buffer.clear()
        else
          _env.out.write(recover val [c.u8()] end)
          _buffer.push(c)
        end
      end
    end

  fun ref dispose() =>
    None


class CreateSubredditInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    
    let body = recover val
      let json = String
      json.append("{")
      json.append("\"name\":\"" + input + "\"")
      json.append("}")
      json
    end
    
    _client.send_request(POST, "/subreddits", headers, body)

  fun ref dispose() =>
    None


class SubscribeSubredditInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    _client.subscribe_to_subreddit_with_data(input)
  
  fun ref dispose() =>
    None


class CreatePostInputNotify is InputNotify
  let _client: RedditRESTClient tag 
  let _env: Env
  var _stage: USize
  var _subreddit: String
  var _title: String
  
  new iso create(client: RedditRESTClient tag, env: Env, stage: USize = 0, 
    subreddit: String = "", title: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _subreddit = subreddit
    _title = title
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _subreddit = input
      _env.out.print("Enter post title:")
      _client.get_input(recover CreatePostInputNotify(_client, _env, 1, _subreddit) end)
    | 1 =>
      _title = input
      _env.out.print("Enter post content:")
      _client.get_input(recover CreatePostInputNotify(_client, _env, 2, _subreddit, _title) end)
    | 2 =>
      _client.create_post_with_data(_subreddit, _title, input)
    end
  
  fun ref dispose() =>
    None


class GetPostInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    _client.get_post_by_id(input)
  
  fun ref dispose() =>
    None


class AddCommentInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  var _stage: USize
  var _post_id: String
  var _subreddit_name: String
  
  new iso create(client: RedditRESTClient, env: Env, stage: USize = 0, post_id: String = "", subreddit_name: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _post_id = post_id
    _subreddit_name = subreddit_name
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _post_id = input
      _env.out.print("Enter subreddit name:")
      _client.get_input(recover AddCommentInputNotify(_client, _env, 1, _post_id) end)
    | 1 =>
      _subreddit_name = input
      _env.out.print("Enter comment content:")
      _client.get_input(recover AddCommentInputNotify(_client, _env, 2, _post_id, _subreddit_name) end)
    | 2 =>
      _client.add_comment_with_data(_post_id, _subreddit_name, input)
    end
  
  fun ref dispose() =>
    None


class ViewCommentsInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    _client.view_post_comments(input)
  
  fun ref dispose() =>
    None


class VotePostInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  var _stage: USize
  var _post_id: String
  var _subreddit_name: String

  new iso create(client: RedditRESTClient, env: Env, stage: USize = 0, post_id: String = "", subreddit_name: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _post_id = post_id
    _subreddit_name = subreddit_name

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _post_id = input
      _env.out.print("Enter subreddit name:")
      _client.get_input(recover VotePostInputNotify(_client, _env, 1, _post_id, "") end)
    | 1 =>
      _subreddit_name = input
      _env.out.print("Enter vote type (up/down):")
      _client.get_input(recover VotePostInputNotify(_client, _env, 2, _post_id, _subreddit_name) end)
    | 2 =>
      let is_upvote = input.lower() == "up"
      _client.vote_on_post_with_data(_post_id, _subreddit_name, is_upvote)
    end

  fun ref dispose() =>
    None


class VoteCommentInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  var _stage: USize
  var _post_id: String
  var _comment_id: String
  var _subreddit_name: String

  new iso create(client: RedditRESTClient, env: Env, stage: USize = 0, post_id: String = "", comment_id: String = "", subreddit_name: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _post_id = post_id
    _comment_id = comment_id
    _subreddit_name = subreddit_name

  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _post_id = input
      _env.out.print("Enter subreddit name:")
      _client.get_input(recover VoteCommentInputNotify(_client, _env, 1, _post_id, "", "") end)
    | 1 =>
      _subreddit_name = input
      _env.out.print("Enter comment ID:")
      _client.get_input(recover VoteCommentInputNotify(_client, _env, 2, _post_id, "", _subreddit_name) end)
    | 2 =>
      _comment_id = input
      _env.out.print("Enter vote type (up/down):")
      _client.get_input(recover VoteCommentInputNotify(_client, _env, 3, _post_id, _comment_id, _subreddit_name) end)
    | 3 =>
      let is_upvote = input.lower() == "up"
      _client.vote_on_comment_with_data(_post_id, _subreddit_name, _comment_id, is_upvote)
    end

  fun ref dispose() =>
    None


class GetFeedInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  let _sort: String
  
  new iso create(client: RedditRESTClient, env: Env, sort: String) =>
    _client = client
    _env = env
    _sort = sort
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    _client.get_subreddit_feed_with_data(input, _sort)
  
  fun ref dispose() =>
    None


class ViewThreadInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  
  new iso create(client: RedditRESTClient, env: Env) =>
    _client = client
    _env = env
  
  fun ref apply(data: Array[U8] iso) =>
    let thread_id = String.from_array(consume data).>trim()
    let headers = recover val 
      let map = Map[String, String]
      map("Content-Type") = "application/json"
      map
    end
    _client.send_request(GET, "/messages/" + thread_id, headers, "")
  
  fun ref dispose() =>
    None


class SendMessageInputNotify is InputNotify
  let _client: RedditRESTClient
  let _env: Env
  var _stage: USize
  var _to_username: String
  
  new iso create(client: RedditRESTClient, env: Env, stage: USize = 0, 
    to_username: String = "") =>
    _client = client
    _env = env
    _stage = stage
    _to_username = to_username
  
  fun ref apply(data: Array[U8] iso) =>
    let input = String.from_array(consume data).>trim()
    
    match _stage
    | 0 =>
      _to_username = input
      _env.out.print("Enter message content:")
      _client.get_input(recover SendMessageInputNotify(_client, _env, 1, _to_username) end)
    | 1 =>
      _client.send_message_with_data(_to_username, input)
    end
  
  fun ref dispose() =>
    None


class LineReaderNotify is InputNotify
  let _input_handler: InputNotify iso
  let _buffer: Array[U8]
  let _env: Env

  new iso create(input_handler: InputNotify iso, env: Env) =>
    _input_handler = consume input_handler
    _buffer = Array[U8]
    _env = env

  fun ref apply(data: Array[U8] iso) =>
    for byte in (consume data).values() do
      if (byte == 8) or (byte == 127) then  // Backspace
        if _buffer.size() > 0 then
          try
            _buffer.pop()?
            _env.out.write(recover val [8; 32; 8] end)
          end
        end
      elseif byte == 10 then  // Enter/Return
        _env.out.write([10])
        let line = recover iso Array[U8] end
        for b in _buffer.values() do
          line.push(b)
        end
        _input_handler.apply(consume line)
        _buffer.clear()
      else
        _buffer.push(byte)
        _env.out.write(recover val [byte] end)
      end
    end

  fun ref dispose() =>
    _input_handler.dispose()
