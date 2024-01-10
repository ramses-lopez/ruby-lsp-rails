require "open3"
require "json"

@stdin, @stdout, @stderr, @wait_thread = Open3.popen3("bin/rails runner lib/ruby_lsp/ruby_lsp_rails/server.rb")
warn("wait thread status = #{@wait_thread.status}")

@stdin.binmode
@stdout.binmode

json = { route: "shutdown" }.to_json
@stdin.write("Content-Length: #{json.length}\r\n\r\n#{json}")
warn(@stderr.read)
