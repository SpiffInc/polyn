# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Access cloud event information
    class CloudEvent
      def self.to_h
        path = File.expand_path(File.join(File.dirname(__FILE__), "../cloud-event-schema.json"))
        file = File.open(path)
        JSON.parse(file.read)
      end
    end
  end
end
