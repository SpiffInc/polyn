// STREAM DEFINITION

resource "jetstream_stream" "WIDGETS" {
  name = "WIDGETS"
  subjects = ["widgets.>"]
  storage = "file"
  max_age  = 60 * 60 * 24 * 365 // 1 year
}

// CONSUMERS

resource "jetstream_consumer" "created_notifier_widgets_created_v1" {
  stream_id = jetstream_stream.WIDGETS.id
  durable_name = "created_notifier_widgets_created_v1"
  deliver_all = true
  filter_subject = "widgets.created.v1"
  sample_freq = 100
}
