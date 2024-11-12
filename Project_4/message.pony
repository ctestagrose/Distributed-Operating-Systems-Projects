use "collections"
use "time"

class val Message
  let sender: String
  let recipient: String
  let content: String
  let timestamp: I64
  let message_id: String
  let thread_id: String
  
  new val create(sender': String, recipient': String, content': String, 
    message_id': String, thread_id': String) =>
    sender = sender'
    recipient = recipient'
    content = content'
    timestamp = Time.now()._1
    message_id = message_id'
    thread_id = thread_id'