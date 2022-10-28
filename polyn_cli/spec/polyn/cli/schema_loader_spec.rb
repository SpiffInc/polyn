# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::Cli::SchemaLoader do
  describe "#load_events" do
    include_context :tmp_dir

    let(:store_name) { "SCHEMA_LOADER_TEST_STORE" }
    let(:thor) { double("thor") }
    let(:nats) { NATS.connect }
    let(:js) { nats.jetstream }
    let(:kv) { js.key_value(store_name) }

    before(:each) do
      allow(thor).to receive(:say)
      js.create_key_value(bucket: store_name)
    end

    after(:each) do
      js.delete_key_value(store_name)
    end

    subject do
      described_class.new(thor,
        store_name: store_name,
        events_dir: tmp_dir)
    end

    it "it loads events to the store" do
      add_schema_file("app.widgets.v1", {
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      })

      subject.load_events

      schema  = get_schema("app.widgets.v1")
      datadef = schema["definitions"]["datadef"]
      expect(datadef).to eq({
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      })
    end

    it "it loads events to the store from subdirectories" do
      add_schema_file("app.widgets.v1", {
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      }, "foo-dir")

      subject.load_events

      schema  = get_schema("app.widgets.v1")
      datadef = schema["definitions"]["datadef"]
      expect(datadef).to eq({
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      })
    end

    it "invalid json schema document raises" do
      add_schema_file("app.widgets.v1", "foo")

      expect { subject.load_events }.to raise_error(Polyn::Cli::ValidationError)
    end

    it "invalid file name raises" do
      add_schema_file("app widgets v1", {
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      })

      expect { subject.load_events }.to raise_error(Polyn::Cli::Error)
    end

    it "non-json documents are ignored" do
      path = File.join(tmp_dir, "foo.png")
      File.write(path, "foo")
      expect { subject.load_events }.to_not raise_error
    end

    it "it raises if two duplicate events exist" do
      add_schema_file("app.widgets.v1", {
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      }, "foo-dir")

      add_schema_file("app.widgets.v1", {
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      }, "bar-dir")

      expect do
        subject.load_events
      end.to raise_error(Polyn::Cli::ValidationError)
    end

    it "it removes deleted events" do
      kv.put("app.widgets.v1", JSON.generate({
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      }))

      subject.load_events

      expect { kv.get("app.widgets.v1") }.to raise_error(NATS::KeyValue::KeyDeletedError)
    end

    it "ignores history of deleted events" do
      kv.put("app.widgets.v1", JSON.generate({
        "type"       => "object",
        "properties" => {
          "name" => { "type" => "string" },
        },
      }))

      kv.delete("app.widgets.v1")

      subject.load_events

      expect { kv.get("app.widgets.v1") }.to raise_error(NATS::KeyValue::KeyDeletedError)
    end

    def add_schema_file(name, content, subdir = "")
      Dir.mkdir(File.join(tmp_dir, subdir)) unless subdir.empty?
      path = File.join(tmp_dir, subdir, "#{name}.json")
      File.write(path, JSON.generate(content))
    end

    def get_schema(name)
      entry = kv.get(name)
      JSON.parse(entry.value)
    end
  end
end
