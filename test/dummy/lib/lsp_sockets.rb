# typed: true
# frozen_string_literal: true

require "socket" # Get sockets from stdlib

# class LspSockets
# end

server = TCPServer.open(2000) # Socket to listen on port 2000
loop do # Servers run forever
  client = server.accept # Wait for a client to connect
  client.puts(Time.now.ctime)   # Send the time to the client
  client.puts "Closing the connection. Bye!"
  client.close                  # Disconnect from the client
end
