# typed: true
# frozen_string_literal: true

class Lsp
  class << self
    def start
      require "webrick"

      server = WEBrick::HTTPServer.new(Port: 8001)
      server.mount_proc("/") do |_req, res|
        res.body = "Hello, world!"
      end

      trap("INT") do
        puts "Shutting down..."
        server.shutdown
      end

      server.start
    end
  end
end

Lsp.start
