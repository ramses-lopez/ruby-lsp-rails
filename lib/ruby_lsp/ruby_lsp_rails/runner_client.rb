# typed: false
# frozen_string_literal: true

require "json" # need?

module RubyLsp
  module Rails
    class RunnerClient
      def initialize
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3("bin/rails runner #{__dir__}/server.rb") # TODO: put back to seperate
        @stdin.binmode # for Windows compatibility
        @stdout.binmode # for Windows compatibility
        $stdin.sync = true
        $stdout.sync = true
      end

      def make_request(request, params = nil)
        warn("***making request #{request}")
        send_request(request, params)
        read_response(request)
      end

      def send_request(request, params = nil)
        hash = {
          method: request,
        }

        hash[:params] = params if params
        json = hash.to_json
        warn("***sending json: #{json}")
        @stdin.write("Content-Length: #{json.length}\r\n\r\n", json)
      end

      def read_response(request)
        Timeout.timeout(5) do
          # Read headers until line breaks
          warn("***r1")
          headers = @stdout.gets("\r\n\r\n")

          # Read the response content based on the length received in the headers
          raw_response = @stdout.read(headers[/Content-Length: (\d+)/i, 1].to_i)
          warn("***r2")
          warn("***r3")

          json = JSON.parse(raw_response, symbolize_keys: true)
          warn("***returning: #{json}")
          json
        end
      rescue Timeout::Error
        raise "Request #{request} timed out. Is the request returning a response?"
      end

      def model(*args)
        make_request("models")
      end

      def shutdown
        warn("*** sending")
        send_request("shutdown")

        @stdin.close
        @stdout.close
        @stderr.close
      end
    end
  end
end
