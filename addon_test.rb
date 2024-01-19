# typed: strict
# frozen_string_literal: true

require "open3"
require "json"

require "sorbet-runtime"
extend T::Sig

@stdin, @stdout, @stderr, @wait_thread = Open3.popen3("bin/rails runner lib/ruby_lsp/ruby_lsp_rails/server.rb")
warn("wait thread status = #{@wait_thread.status}")

# for windows
# @stdin.binmode
# @stdout.binmode

json = { method: "models", params: "User" }.to_json
@stdin.write("Content-Length: #{json.length}\r\n\r\n#{json}")

headers = T.must(@stdout.gets("\r\n\r\n"))
response = @stdout.read(headers[/Content-Length: (\d+)/i, 1].to_i)

puts "response: " + response
puts "stderr: #{@stderr}"
puts "wait thread status after first write = #{@wait_thread.status}"
# $stdin.read

json = { method: "shutdown", params: "User" }.to_json
@stdin.write("Content-Length: #{json.length}\r\n\r\n#{json}")
puts "wait thread status after second write = #{@wait_thread.status}"
