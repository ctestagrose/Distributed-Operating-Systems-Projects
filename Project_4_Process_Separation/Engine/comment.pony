use "collections"
use "random"
use "time"

class Comment
  let author: String
  let content: String
  var replies: Array[Comment] ref
  var upvotes: Set[String] ref
  var downvotes: Set[String] ref
  let created_at: I64 
  
  new create(author': String, content': String) =>
    author = author'
    content = content'
    replies = Array[Comment]
    upvotes = Set[String]
    downvotes = Set[String]
    upvotes.set(author)
    created_at = Time.now()._1
    upvotes.set(author)
    
  fun ref add_reply(reply: Comment) =>
    replies.push(reply)
    
  fun get_author(): String =>
    author
    
  fun get_content(): String =>
    content
    
  fun ref get_replies(): Array[Comment] ref =>
    replies

  fun get_reply_count(): USize =>
    var total = replies.size()
    for reply in replies.values() do
      total = total + reply.get_reply_count()
    end
    total

  fun ref upvote(username: String) =>
    downvotes.unset(username)
    upvotes.set(username)
    
  fun ref downvote(username: String) =>
    upvotes.unset(username)  
    downvotes.set(username)

  fun get_score(): I64 =>
    upvotes.size().i64() - downvotes.size().i64()

  fun get_controversy_score(): F64 =>
    if (upvotes.size() + downvotes.size()) == 0 then
      0
    else
      let ups = upvotes.size().f64()
      let downs = downvotes.size().f64()
      (ups * downs) / ((ups + downs)*(ups + downs)).f64()
    end

  fun get_nested_level(): USize =>
    var level: USize = 0
    for reply in replies.values() do
      let reply_level = reply.get_nested_level() + 1
      if reply_level > level then
        level = reply_level
      end
    end
    level
