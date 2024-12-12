
primitive JsonBuilder
  fun user_to_json(username: String, bio: String = ""): String =>
    "{\"username\":\"" + username + "\",\"bio\":\"" + bio + "\"}"
    
  fun post_to_json(username: String, title: String, content: String): String =>
    "{\"username\":\"" + username + "\",\"title\":\"" + title + 
    "\",\"content\":\"" + content + "\"}"
    
  fun comment_to_json(username: String, content: String): String =>
    "{\"username\":\"" + username + "\",\"content\":\"" + content + "\"}"
    
  fun vote_to_json(username: String, is_upvote: Bool): String =>
    "{\"username\":\"" + username + "\",\"upvote\":" + 
    if is_upvote then "true" else "false" end + "}"