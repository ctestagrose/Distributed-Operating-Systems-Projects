use "collections"
use "format"
use "../Engine"

primitive JsonBuilder
  fun feed_to_json(feed: PostFeed): String =>
    let response = recover iso String end
    response.append("{\"posts\":[")
    
    var first = true
    for post in feed.posts.values() do
      if not first then response.append(",") end
      response.append("{")
      response.append("\"id\":" + post.id.string() + ",")
      response.append("\"title\":\"" + post.title.clone().>replace("\"", "\\\"") + "\",")
      response.append("\"author\":\"" + post.author.clone().>replace("\"", "\\\"") + "\",")
      response.append("\"content\":\"" + post.content.clone().>replace("\"", "\\\"") + "\",")
      response.append("\"score\":" + post.get_score().string() + ",")
      response.append("\"upvotes\":" + post.upvotes.size().string() + ",")
      response.append("\"downvotes\":" + post.downvotes.size().string() + ",")
      response.append("\"commentCount\":" + post.get_comments().size().string())
      response.append("}")
      first = false
    end
    
    response.append("]}")
    
    let result = consume response
    if result == "{\"posts\":[]}" then
      "{\"posts\":[],\"message\":\"No posts found in subscribed subreddits\"}"
    else
      result
    end

  fun post_to_json(post: RedditPost): String val =>
    let json = recover iso String end
    json.append("{")
    json.append("\"id\":" + post.id.string() + ",")
    json.append("\"title\":\"" + post.title + "\",")
    json.append("\"author\":\"" + post.author + "\",")
    json.append("\"content\":\"" + post.content + "\",")
    json.append("\"score\":" + post.get_score().string() + ",")
    json.append("\"upvotes\":" + post.upvotes.size().string() + ",")
    json.append("\"downvotes\":" + post.downvotes.size().string() + ",")
    json.append("\"commentCount\":" + post.get_comments().size().string() + ",")
    json.append("\"hotScore\":" + post.get_hot_score().string() + ",")
    json.append("\"controversyScore\":" + post.get_controversy_score().string() + ",")
    json.append("\"comments\":" + comments_to_json(post.get_comments()))
    json.append("}")
    consume json

  fun post_with_comments(post: RedditPost): String val =>
    let json = recover iso String end
    json.append("{")
    json.append("\"post\":" + post_to_json(post) + ",")
    json.append("\"comments\":" + comments_to_json(post.get_comments()))
    json.append("}")
    consume json

  fun comments_to_json(comments: Array[Comment] ref): String val =>
    let json = recover iso String end
    json.append("[")
    var first = true
    for comment in comments.values() do
      if not first then json.append(",") end
      json.append(comment_to_json(comment))
      first = false
    end
    json.append("]")
    consume json

  fun comment_to_json(comment: Comment): String val =>
    let json = recover iso String end
    json.append("{")
    json.append("\"author\":\"" + comment.get_author() + "\",")
    json.append("\"content\":\"" + comment.get_content() + "\",")
    json.append("\"score\":" + comment.get_score().string() + ",")
    json.append("\"upvotes\":" + comment.upvotes.size().string() + ",")
    json.append("\"downvotes\":" + comment.downvotes.size().string() + ",")
    json.append("\"replies\":" + comments_to_json(comment.get_replies()) + ",")
    json.append("\"created_at\":" + comment.created_at.string())
    json.append("}")
    consume json

class val JsonPost
  let title: String
  let author: String
  let content: String
  let score: I64
  
  new val create(title': String, author': String, content': String, score': I64) =>
    title = title'
    author = author'
    content = content'
    score = score'

primitive JsonParser
  fun parse(json_str: String val, env: Env): Map[String, (String | Bool)]? =>
    env.out.print("=== JSON Parser Input ===")
    env.out.print("Raw input: '" + json_str + "'")
    
    let result = Map[String, (String | Bool)]
    
    try
      let content = recover val
        let tmp = String(json_str.size())
        var in_string = false
        var escaped = false
        
        for c in json_str.values() do
          match c
          | '"' if not escaped => 
            in_string = not in_string
            tmp.push(c)
          | '\\' if in_string => 
            escaped = true
            tmp.push(c)
          | ' ' | '\t' | '\n' | '\r' if not in_string => None
          else
            if escaped then
              escaped = false
            end
            tmp.push(c)
          end
        end
        tmp
      end
      
      if (content.size() < 2) or (content(0)? != '{') or (content(content.size()-1)? != '}') then
        env.out.print("Invalid JSON format - Missing braces")
        error
      end
      
      let inner_content = recover val
        content.substring(ISize(1), ISize.from[USize](content.size() - 1))
      end
      
      let pairs = recover val inner_content.split(",") end
      
      for pair in pairs.values() do
        try
          let pair_parts = recover val pair.split(":", 2) end
          
          let raw_key = pair_parts(0)?
          let raw_value = pair_parts(1)?
          
          let key = recover val
            let tmp = String
            var started = false
            for c in raw_key.values() do
              if not started and (c == '"') then
                started = true
              elseif started and (c != '"') then
                tmp.push(c)
              end
            end
            tmp
          end
          
          let trimmed_value = recover val
            String.join(raw_value.split(" ").values())
          end
          
          if trimmed_value == "true" then
            result(key) = true
          elseif trimmed_value == "false" then
            result(key) = false
          else
            let value = recover val
              let tmp = String
              var started = false
              for c in raw_value.values() do
                if not started and (c == '"') then
                  started = true
                elseif started and (c != '"') then
                  tmp.push(c)
                end
              end
              tmp
            end
            result(key) = value
          end
          
        else
          env.out.print("Error processing pair")
          error
        end
      end
      
      env.out.print("Successfully parsed " + result.size().string() + " pairs")
      result
      
    else
      env.out.print("JSON parsing failed")
      error
    end