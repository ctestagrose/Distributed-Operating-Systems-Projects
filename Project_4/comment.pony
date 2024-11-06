use "collections"
use "random"
use "time"

class Comment
  let author: String
  let content: String
  var replies: Array[Comment] ref
  var upvotes: Set[String] ref
  var downvotes: Set[String] ref
  
  new create(author': String, content': String) =>
    author = author'
    content = content'
    replies = Array[Comment]
    upvotes = Set[String]
    downvotes = Set[String]
    upvotes.set(author)
    
  fun ref add_reply(reply: Comment) =>
    replies.push(reply)
    
  fun get_author(): String =>
    author
    
  fun get_content(): String =>
    content
    
  fun ref get_replies(): Array[Comment] ref =>
    replies

  fun ref upvote(username: String) =>
    downvotes.unset(username)  // Remove downvote if exists
    upvotes.set(username)
    
  fun ref downvote(username: String) =>
    upvotes.unset(username)    // Remove upvote if exists
    downvotes.set(username)

  fun get_score(): I64 =>
    upvotes.size().i64() - downvotes.size().i64()

