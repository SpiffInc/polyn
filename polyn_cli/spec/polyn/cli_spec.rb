# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::Cli do
  subject do
    Polyn::Cli::Commands.new
  end

  it "has a version number" do
    expect(Polyn::Cli::VERSION).not_to be nil
  end

  describe "#init" do
    include_context :tmp_dir
    it "creates a new codebase" do
      subject.invoke(:init, [], { dir: tmp_dir })
      expect(File.exist?(File.join(tmp_dir, "tf/kv_buckets.tf"))).to be true
      expect(File.exist?(File.join(tmp_dir, "tf/provider.tf"))).to be true
      expect(File.exist?(File.join(tmp_dir, "tf/variables.tf"))).to be true
      expect(File.exist?(File.join(tmp_dir, "tf/versions.tf"))).to be true
      expect(File.exist?(File.join(tmp_dir, "tf/widgets.tf"))).to be true
      expect(File.exist?(File.join(tmp_dir, "schemas/widgets.created.v1.json"))).to be true
      expect(File.exist?(File.join(tmp_dir, "README.md"))).to be true
      expect(File.exist?(File.join(tmp_dir, "Gemfile"))).to be true
      expect(File.read(File.join(tmp_dir, "Gemfile"))).to include(Polyn::Cli::VERSION)
      expect(File.exist?(File.join(tmp_dir, ".gitignore"))).to be true
      expect(File.exist?(File.join(tmp_dir, "docker-compose.yml"))).to be true
    end
  end

  describe "#gen:stream" do
    include_context :tmp_dir
    it "it creates a new stream file" do
      subject.invoke("gen:stream", ["foo"], { dir: tmp_dir })
      path = File.join(tmp_dir, "tf/foo.tf")
      expect(File.exist?(path)).to be true
      file = File.read(path)
      expect(file).to include(%(resource "jetstream_stream" "FOO"))
      expect(file).to include(%(\n// CONSUMERS))
    end

    it "raises if stream name is invalid" do
      expect do
        subject.invoke("gen:stream", ["foo bar baz"], { dir: tmp_dir })
      end.to raise_error(Polyn::Cli::Error)
    end
  end

  describe "#gen:consumer" do
    include_context :tmp_dir

    before(:each) do
      Dir.mkdir(File.join(tmp_dir, "schemas"))
    end

    it "it adds consumer config to existing stream file" do
      add_schema
      subject.invoke("gen:stream", ["foo_stream"], { dir: tmp_dir })
      subject.invoke("gen:consumer", ["foo_stream", "users.backend", "user.updated.v1"],
        { dir: tmp_dir })
      file = File.read(File.join(tmp_dir, "tf/foo_stream.tf"))
      expect(file).to include(%(resource "jetstream_consumer" "users_backend_user_updated_v1"))
      expect(file).to include(%(stream_id = jetstream_stream.FOO_STREAM.id))
      expect(file).to include(%(durable_name = "users_backend_user_updated_v1"))
      expect(file).to include(%(filter_subject = "user.updated.v1"))
    end

    it "it raises if stream file is non-existant" do
      add_schema
      expect do
        subject.invoke("gen:consumer", ["foo_stream", "users.backend", "user.updated.v1"],
          { dir: tmp_dir })
      end.to raise_error(Polyn::Cli::Error)
    end

    it "it raises if the event has no schema" do
      subject.invoke("gen:stream", ["foo_stream"], { dir: tmp_dir })
      expect do
        subject.invoke("gen:consumer", ["foo_stream", "users.backend", "user.updated.v1"],
          { dir: tmp_dir })
      end.to raise_error(Polyn::Cli::Error)
    end

    it "raises if stream name is invalid" do
      subject.invoke("gen:stream", ["foo_stream"], { dir: tmp_dir })
      add_schema
      expect do
        subject.invoke("gen:consumer", ["foo stream", "users.backend", "user.updated.v1"],
          { dir: tmp_dir })
      end.to raise_error(Polyn::Cli::Error)
    end

    it "raises if destination name is invalid" do
      subject.invoke("gen:stream", ["foo_stream"], { dir: tmp_dir })
      add_schema
      expect do
        subject.invoke("gen:consumer", ["foo_stream", "users backend", "user.updated.v1"],
          { dir: tmp_dir })
      end.to raise_error(Polyn::Cli::Error)
    end

    it "raises if event_type name is invalid" do
      subject.invoke("gen:stream", ["foo_stream"], { dir: tmp_dir })
      add_schema
      expect do
        subject.invoke("gen:consumer", ["foo_stream", "users.backend", "user updated v1"],
          { dir: tmp_dir })
      end.to raise_error(Polyn::Cli::Error)
    end
  end

  describe "#gen:schema" do
    include_context :tmp_dir
    it "it creates a new schema file" do
      subject.invoke("gen:schema", ["foo"], { dir: tmp_dir })
      path = File.join(tmp_dir, "schemas/foo.json")
      expect(File.exist?(path)).to be true
      file = File.read(path)
      expect(file).to include(%("$id": "foo"))
    end

    it "it creates a new schema file in a subdirectory" do
      subject.invoke("gen:schema", ["some/deep/dir/foo"], { dir: tmp_dir })
      path = File.join(tmp_dir, "schemas/some/deep/dir/foo.json")
      expect(File.exist?(path)).to be true
      file = File.read(path)
      expect(file).to include(%("$id": "foo"))
    end

    it "raises if event_type is invalid" do
      expect do
        subject.invoke("gen:schema", ["foo bar baz"], { dir: tmp_dir })
      end.to raise_error(Polyn::Cli::Error)
    end
  end

  def add_schema
    File.open(File.join(tmp_dir, "schemas/user.updated.v1.json"), "w+") do |file|
      file.write("boo!")
    end
  end
end
