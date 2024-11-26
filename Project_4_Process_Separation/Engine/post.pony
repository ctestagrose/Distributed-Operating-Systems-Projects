use "collections"
use "random"
use "time"
use "math"

primitive MathUtils
  fun log10(x: F64): F64 =>
    if x <= 0 then
      0.0
    else
      x.log() / F64(10.0).log()
    end

class Post
  let title: String
  let content: String
  let author: String
  let created_at: I64
  var comments: Array[Comment] ref
  var upvotes: Set[String] ref
  var downvotes: Set[String] ref
  
  new create(title': String, content': String, author': String) =>
    title = title'
    content = content'
    author = author'
    created_at = Time.now()._1
    comments = Array[Comment]
    upvotes = Set[String]
    downvotes = Set[String]
    upvotes.set(author)
    
  fun ref add_comment(comment_author: String, comment_content: String) =>
    let comment = Comment(comment_author, comment_content)
    comments.push(comment)
    
  fun ref get_comments(): Array[Comment] ref =>
    comments

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

  fun get_hot_score(): F64 =>
    let score = get_score().f64()
    let order = if score > 0 then
      MathUtils.log10(score.max(1))
    else
      MathUtils.log10(score.abs().max(1)) * -1
    end
    let seconds = created_at - 1134028003
    order + (seconds.f64() / 45000)
    