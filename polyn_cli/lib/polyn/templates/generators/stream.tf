// STREAM DEFINITION

resource "jetstream_stream" "<%= stream_name %>" {
  name = "<%= stream_name %>"
  subjects = []
  storage = "file"
  max_age  = 60 * 60 * 24 * 365 // 1 year
}

// CONSUMERS