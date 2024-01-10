# typed: false
# frozen_string_literal: true

running = true
while running
  warn "***runnning"
  headers = $stdin.gets("\r\n\r\n")
  warn "***headers: #{headers}"
  # Read the response content based on the length received in the headers
  request = $stdin.read(headers[/Content-Length: (\d+)/i, 1].to_i)
  json = JSON.parse(request, symbolize_names: true)
  request_route = json.fetch(:route)
  # params = json.fetch(:params)
  case request_route
  when "shutdown"
    warn("cols: #{User.column_names}")
    warn("shutting down")
    running = false
  end
end
