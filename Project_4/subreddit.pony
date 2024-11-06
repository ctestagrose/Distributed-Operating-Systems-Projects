use "collections"
use "random"
use "time"

class Subreddit
  let name: String
  var members: Set[String] ref
  var posts: Array[Post] ref

  new create(name': String) =>
    name = name'
    members = Set[String]
    posts = Array[Post]

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

  fun ref create_post(title: String, content: String, author: String): Bool =>
    if members.contains(author) then
      let post = Post(title, content, author)
      posts.push(post)
      true
    else
      false
    end
    
  fun ref get_posts(): Array[Post] ref =>
    posts

  fun ref get_sorted_posts(sort_type: U8): Array[Post] ref^ =>
    PostSorter(posts, sort_type)

  fun ref add_comment_to_post(post_index: USize, author: String, content: String): Bool =>
    try
      if members.contains(author) then
        posts(post_index)?.add_comment(author, content)
        true
      else
        false
      end
    else
      false
    end

  fun ref vote_on_post(post_index: USize, username: String, is_upvote: Bool): Bool =>
    try
      if members.contains(username) then
        let post = posts(post_index)?
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


primitive SortType
  fun hot(): U8 => 0
  fun controversial(): U8 => 1
  fun top(): U8 => 2
  fun new_p(): U8 => 3

primitive PostSorter
  fun apply(posts: Array[Post] ref, sort_type: U8): Array[Post] ref^ =>
    """
    Sorts posts based on the specified sort type.
    Returns a new array containing sorted posts.
    """
    match sort_type
    | SortType.hot() => sort_by_hot(posts)
    | SortType.controversial() => sort_by_controversial(posts)
    | SortType.top() => sort_by_top(posts)
    | SortType.new_p() => sort_by_new(posts)
    else
      sort_by_hot(posts) // Default to hot sort
    end

  fun sort_by_hot(posts: Array[Post] ref): Array[Post] ref^ =>
    """
    Sorts posts by hot score (combination of score and time)
    """
    let sorted = posts.clone()
    _quicksort_by[F64](sorted, {(post: Post): F64 => post.get_hot_score()}, 0, sorted.size().isize() - 1)
    sorted

  fun sort_by_controversial(posts: Array[Post] ref): Array[Post] ref^ =>
    """
    Sorts posts by controversy score
    """
    let sorted = posts.clone()
    _quicksort_by[F64](sorted, {(post: Post): F64 => post.get_controversy_score()}, 0, sorted.size().isize() - 1)
    sorted

  fun sort_by_top(posts: Array[Post] ref): Array[Post] ref^ =>
    """
    Sorts posts by total score (upvotes - downvotes)
    """
    let sorted = posts.clone()
    _quicksort_by[I64](sorted, {(post: Post): I64 => post.get_score()}, 0, sorted.size().isize() - 1)
    sorted

  fun sort_by_new(posts: Array[Post] ref): Array[Post] ref^ =>
    """
    Sorts posts by creation time
    """
    let sorted = posts.clone()
    _quicksort_by[I64](sorted, {(post: Post): I64 => post.created_at}, 0, sorted.size().isize() - 1)
    sorted

  fun _quicksort_by[A: (Comparable[A] #read & (I64 | F64))](
    arr: Array[Post] ref,
    get_value: {(Post): A} val,
    left: ISize,
    right: ISize)
  =>
    """
    Generic quicksort implementation that sorts posts based on a value extractor function.
    Uses the median-of-three method for pivot selection to improve performance on
    partially sorted arrays.
    """
    if left >= right then return end
    
    try
      // Get the pivot using median-of-three method
      let mid = (left + right) / 2
      let pivot_idx = _median_of_three[A](arr, get_value, left, mid, right)?
      
      // Move pivot to end
      arr.swap_elements(pivot_idx.usize(), right.usize())?
      let pivot_value = get_value(arr(right.usize())?)
      
      // Partition
      var store_idx = left
      var i = left
      while i < right do
        if get_value(arr(i.usize())?) > pivot_value then
          arr.swap_elements(store_idx.usize(), i.usize())?
          store_idx = store_idx + 1
        end
        i = i + 1
      end
      
      // Move pivot to final position
      arr.swap_elements(store_idx.usize(), right.usize())?
      
      // Recursively sort sub-arrays
      _quicksort_by[A](arr, get_value, left, store_idx - 1)
      _quicksort_by[A](arr, get_value, store_idx + 1, right)
    end

  fun _median_of_three[A: (Comparable[A] #read & (I64 | F64))](
    arr: Array[Post] ref,
    get_value: {(Post): A} val,
    left: ISize,
    mid: ISize,
    right: ISize): ISize?
  =>
    """
    Helper function to find the median of three elements.
    Returns the index of the median value.
    """
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
