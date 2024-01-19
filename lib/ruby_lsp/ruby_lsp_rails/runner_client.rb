# typed: false
# frozen_string_literal: true

require "json" # need?

module RubyLsp
  module Rails
    class RunnerClient
      def initialize
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3("bin/rails", "runner", "#{__dir__}/server.rb")
        @stdin.binmode # for Windows compatibility
        @stdout.binmode # for Windows compatibility
      end

      def make_request(request, params = nil)
        send_request(request, params)
        read_response(request)
      end

      def send_request(request, params = nil)
        hash = {
          method: request,
        }

        hash[:params] = params if params
        json = hash.to_json
        @stdin.write("Content-Length: #{json.length}\r\n\r\n", json)
      end

      def read_response(request)
        Timeout.timeout(5) do
          headers = @stdout.gets("\r\n\r\n")
          raw_response = @stdout.read(headers[/Content-Length: (\d+)/i, 1].to_i)
          JSON.parse(raw_response, symbolize_keys: true)
        end
      rescue Timeout::Error
        raise "Request #{request} timed out. Is the request returning a response?"
      end

      def model(name)
        make_request("models", name: name)
      end

      def shutdown
        send_request("shutdown")

        @stdin.close
        @stdout.close
        @stderr.close
      end
    end
  end
end
