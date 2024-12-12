use "collections"
use "random"
use "time"

class Subreddit
  let name: String
  var members: Set[String] ref
  var posts: Map[USize, RedditPost] ref  // Change Array to Map with ID as key
  var next_post_id: USize  // Add post ID counter

  new create(name': String) =>
    name = name'
    members = Set[String]
    posts = Map[USize, RedditPost]
    next_post_id = 0

  fun ref add_member(username: String) =>
    members.set(username)

  fun ref remove_member(username: String) =>
    members.unset(username)

  fun get_member_count(): USize =>
    members.size()

  fun ref get_members(): Set[String] ref =>  
    members

  fun get_members_clone(): Set[String] =>    
    members.clone()

  fun ref create_post(title: String, content: String, author: String): (USize | None) =>
    if members.contains(author) then
      let post_id = next_post_id
      next_post_id = next_post_id + 1
      let post = RedditPost(post_id, title, content, author)
      posts(post_id) = post
      post_id  // Return the ID of the created post
    else
      None
    end
    
  fun ref get_posts(): Map[USize, RedditPost] ref =>
    posts

  fun ref get_post(id: USize): RedditPost ? =>
    posts(id)?

  fun ref get_posts_array(): Array[RedditPost] ref^ =>
    let arr = recover ref Array[RedditPost] end
    for post in posts.values() do
      arr.push(post)
    end
    arr

  fun ref get_sorted_posts(sort_type: U8): Array[RedditPost] ref^ =>
    let posts_arr = get_posts_array()
    PostSorter(posts_arr, sort_type)

  fun ref add_comment_to_post(post_id: USize, author: String, content: String): Bool =>
    try
      if members.contains(author) then
        posts(post_id)?.add_comment(author, content)
        true
      else
        false
      end
    else
      false
    end

  fun ref vote_on_post(post_id: USize, username: String, is_upvote: Bool): Bool =>
    try
      if members.contains(username) then
        let post = posts(post_id)?
        if is_upvote then
          post.upvote(username)
        else
          post.downvote(username)
        end
        true
      else
        false
      end
    else
      false
    end

  fun ref vote_on_comment(post_index: USize, comment_index: USize, username: String, is_upvote: Bool): Bool =>
    try
      if members.contains(username) then
        let comment = posts(post_index)?.get_comments()(comment_index)?
        if is_upvote then
          comment.upvote(username)
        else
          comment.downvote(username)
        end
        true
      else
        false
      end
    else
      false
    end

fun ref add_nested_comment(post_index: USize, parent_comment_indices: Array[USize], 
  author: String, content: String): Bool =>
  try
    if members.contains(author) then
      let post = posts(post_index)?
      var current_comments = post.get_comments()
      
      if parent_comment_indices.size() > 0 then
        var target_comment: Comment = current_comments(parent_comment_indices(0)?)?
        
        for i in Range(1, parent_comment_indices.size()) do
          let idx = parent_comment_indices(i)?
          current_comments = target_comment.get_replies()
          target_comment = current_comments(idx)?
        end
        
        let new_comment = Comment(author, content)
        target_comment.add_reply(new_comment)
      else
        post.add_comment(author, content)
      end
      true
    else
      false
    end
  else
    false
  end

  fun ref vote_on_nested_comment(post_index: USize, comment_indices: Array[USize], 
    username: String, is_upvote: Bool): Bool =>
    try
      if members.contains(username) then
        let post = posts(post_index)?
        var current_comments = post.get_comments()
        var target_comment: Comment = current_comments(comment_indices(0)?)?
        
        for i in Range(1, comment_indices.size()) do
          let idx = comment_indices(i)?
          current_comments = target_comment.get_replies()
          target_comment = current_comments(idx)?
        end
        
        if is_upvote then
          target_comment.upvote(username)
        else
          target_comment.downvote(username)
        end
        true
      else
        false
      end
    else
      false
    end


primitive SortType
  fun hot(): U8 => 0
  fun controversial(): U8 => 1
  fun top(): U8 => 2
  fun new_p(): U8 => 3

primitive PostSorter
  fun apply(posts: Array[RedditPost] ref, sort_type: U8): Array[RedditPost] ref^ =>
    match sort_type
    | SortType.hot() => sort_by_hot(posts)
    | SortType.controversial() => sort_by_controversial(posts)
    | SortType.top() => sort_by_top(posts)
    | SortType.new_p() => sort_by_new(posts)
    else
      sort_by_hot(posts) // Default to hot sort
    end

  fun sort_by_hot(posts: Array[RedditPost] ref): Array[RedditPost] ref^ =>
    let sorted = posts.clone()
    _quicksort_by[F64](sorted, {(post: RedditPost): F64 => post.get_hot_score()}, 0, sorted.size().isize() - 1)
    sorted

  fun sort_by_controversial(posts: Array[RedditPost] ref): Array[RedditPost] ref^ =>
    let sorted = posts.clone()
    _quicksort_by[F64](sorted, {(post: RedditPost): F64 => post.get_controversy_score()}, 0, sorted.size().isize() - 1)
    sorted

  fun sort_by_top(posts: Array[RedditPost] ref): Array[RedditPost] ref^ =>
    let sorted = posts.clone()
    _quicksort_by[I64](sorted, {(post: RedditPost): I64 => post.get_score()}, 0, sorted.size().isize() - 1)
    sorted

  fun sort_by_new(posts: Array[RedditPost] ref): Array[RedditPost] ref^ =>
    let sorted = posts.clone()
    _quicksort_by[I64](sorted, {(post: RedditPost): I64 => post.created_at}, 0, sorted.size().isize() - 1)
    sorted

  fun _quicksort_by[A: (Comparable[A] #read & (I64 | F64))](
    arr: Array[RedditPost] ref,
    get_value: {(RedditPost): A} val,
    left: ISize,
    right: ISize) =>
    if left >= right then return end
    
    try
      let mid = (left + right) / 2
      let pivot_idx = _median_of_three[A](arr, get_value, left, mid, right)?
      
      arr.swap_elements(pivot_idx.usize(), right.usize())?
      let pivot_value = get_value(arr(right.usize())?)
      
      var store_idx = left
      var i = left
      while i < right do
        if get_value(arr(i.usize())?) > pivot_value then
          arr.swap_elements(store_idx.usize(), i.usize())?
          store_idx = store_idx + 1
        end
        i = i + 1
      end
      
      arr.swap_elements(store_idx.usize(), right.usize())?
      
      _quicksort_by[A](arr, get_value, left, store_idx - 1)
      _quicksort_by[A](arr, get_value, store_idx + 1, right)
    end

  fun _median_of_three[A: (Comparable[A] #read & (I64 | F64))](
    arr: Array[RedditPost] ref,
    get_value: {(RedditPost): A} val,
    left: ISize,
    mid: ISize,
    right: ISize): ISize? =>
    let a = get_value(arr(left.usize())?)
    let b = get_value(arr(mid.usize())?)
    let c = get_value(arr(right.usize())?)
    
    if (a > b) then
      if (b > c) then
        mid
      elseif (a > c) then
        right
      else
        left
      end
    else
      if (a > c) then
        left
      elseif (b > c) then
        right
      else
        mid
      end
    end
