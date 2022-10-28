# frozen_string_literal: true

require "spec_helper"

RSpec.describe Polyn::Cli::Naming do
  describe "#validate_stream_name!" do
    it "allows underscore separator" do
      expect { described_class.validate_stream_name!("foo_bar") }.to_not raise_error
    end

    it "allows lowercase" do
      expect { described_class.validate_stream_name!("foo") }.to_not raise_error
    end

    it "allows uppercase" do
      expect { described_class.validate_stream_name!("FOO") }.to_not raise_error
    end

    it "allows numbers" do
      expect { described_class.validate_stream_name!("FOO1") }.to_not raise_error
    end

    it "raises if spaces" do
      expect { described_class.validate_stream_name!("foo bar") }.to raise_error(Polyn::Cli::Error)
    end

    it "raises if non underscore special char" do
      expect { described_class.validate_stream_name!("foo-bar") }.to raise_error(Polyn::Cli::Error)
    end
  end

  describe "#validate_destination_name" do
    it "valid name that's alphanumeric and dot separated passes" do
      expect { described_class.validate_destination_name!("com.test") }.to_not raise_error
    end

    it "valid name that's alphanumeric and dot separated (3 dots) passes" do
      expect { described_class.validate_destination_name!("com.test.foo") }.to_not raise_error
    end

    it "valid name that's alphanumeric and colon separated passes" do
      expect { described_class.validate_destination_name!("com:test") }.to_not raise_error
    end

    it "name can't have spaces" do
      expect do
        described_class.validate_destination_name!("user   created")
      end.to raise_error(Polyn::Cli::Error)
    end

    it "name can't have tabs" do
      expect { described_class.validate_destination_name!("user\tcreated") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't have linebreaks" do
      expect { described_class.validate_destination_name!("user\n\rcreated") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't have special characters" do
      expect { described_class.validate_destination_name!("user:*%[]<>$!@#-_created") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't start with a dot" do
      expect { described_class.validate_destination_name!(".user") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't end with a dot" do
      expect { described_class.validate_destination_name!("user.") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't start with a colon" do
      expect { described_class.validate_destination_name!(":user") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't end with a colon" do
      expect { described_class.validate_destination_name!("user:") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't be nil" do
      expect { described_class.validate_destination_name!(nil) }
        .to raise_error(Polyn::Cli::Error)
    end
  end

  describe "#validate_event_type!" do
    it "valid name that's alphanumeric and dot separated passes" do
      expect { described_class.validate_event_type!("user.created") }.to_not raise_error
    end

    it "valid name that's alphanumeric and dot separated (3 dots) passes" do
      expect { described_class.validate_event_type!("user.created.foo") }.to_not raise_error
    end

    it "name can't have colons" do
      expect do
        described_class.validate_event_type!("user:test")
      end.to raise_error(Polyn::Cli::Error)
    end

    it "name can't have spaces" do
      expect do
        described_class.validate_event_type!("user   created")
      end.to raise_error(Polyn::Cli::Error)
    end

    it "name can't have tabs" do
      expect { described_class.validate_event_type!("user\tcreated") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't have linebreaks" do
      expect { described_class.validate_event_type!("user\n\rcreated") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't have special characters" do
      expect { described_class.validate_event_type!("user:*%[]<>$!@#-_created") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't start with a dot" do
      expect { described_class.validate_event_type!(".user") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't end with a dot" do
      expect { described_class.validate_event_type!("user.") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't start with a colon" do
      expect { described_class.validate_event_type!(":user") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't end with a colon" do
      expect { described_class.validate_event_type!("user:") }
        .to raise_error(Polyn::Cli::Error)
    end

    it "name can't be nil" do
      expect { described_class.validate_event_type!(nil) }
        .to raise_error(Polyn::Cli::Error)
    end
  end

  describe "#dot_to_underscore" do
    it "turns dot to underscore" do
      expect(described_class.dot_to_underscore("foo.bar.baz")).to eq("foo_bar_baz")
    end
  end

  describe "#colon_to_underscore" do
    it "turns colon to underscore" do
      expect(described_class.colon_to_underscore("foo:bar:baz")).to eq("foo_bar_baz")
    end
  end

  describe "#dot_to_colon" do
    it "replaces dots" do
      expect(described_class.dot_to_colon("com.acme.user.created.v1.schema.v1")).to eq("com:acme:user:created:v1:schema:v1")
    end
  end
end
