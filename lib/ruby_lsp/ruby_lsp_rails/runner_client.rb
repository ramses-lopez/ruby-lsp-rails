# typed: strict
# frozen_string_literal: true

require "json"
require "open3"

module RubyLsp
  module Rails
    class RunnerClient
      extend T::Sig

      sig { void }
      def initialize
        stdin, stdout, stderr, wait_thread = Open3.popen3(
          "bin/rails",
          "runner",
          "#{__dir__}/server.rb",
        )
        @stdin = T.let(stdin, IO)
        @stdout = T.let(stdout, IO)
        @stderr = T.let(stderr, IO)
        # TODO: clean up T.must calls
        @wait_thread = T.let(wait_thread, Thread)
        @stdin.binmode # for Windows compatibility
        @stdout.binmode # for Windows compatibility
      end

      sig { params(request: T.untyped, params: T.untyped).returns(T.untyped) }
      def make_request(request, params = nil)
        send_request(request, params)
        read_response(request)
      end

      sig { params(request: T.untyped, params: T.untyped).void }
      def send_request(request, params = nil)
        hash = {
          method: request,
        }

        hash[:params] = params if params
        json = hash.to_json
        # need to fix upstream to accept multiple args (in Sorbet)?
        @stdin.write("Content-Length: #{json.length}\r\n\r\n" + json)
      end

      sig { params(request: T.untyped).returns(T::Hash[String, String]) }
      def read_response(request) # TODO: request not used
        # Timeout.timeout(5) do
        headers = @stdout.gets("\r\n\r\n")

        raw_response = @stdout.read(T.must(headers)[/Content-Length: (\d+)/i, 1].to_i)
        JSON.parse(T.must(raw_response), symbolize_keys: true)
        # end
        # rescue Timeout::Error
        #   raise "Request #{request} timed out. Is the request returning a response?"
      rescue => e
        # warn(e.backtrace)
        warn(@stderr.read)
        raise
      end

      sig { params(name: String).returns(String) }
      def model(name)
        make_request("models", name: name)
      end

      sig { void }
      def shutdown
        send_request("shutdown")
        sleep(0.01) while @wait_thread.alive?

        @stdin.close
        @stdout.close
        @stderr.close
      end
    end
  end
end
