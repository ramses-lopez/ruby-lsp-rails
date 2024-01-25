# typed: true # rubocop:disable Sorbet/StrictSigil
# frozen_string_literal: true

require "json"
require "sorbet-runtime"

$stdin.sync = true
$stdout.sync = true

# TODO: move into a class/module
def resolve_database_info_from_model(model_name)
  const = ActiveSupport::Inflector.safe_constantize(model_name)
  return unless const && const < ActiveRecord::Base

  begin
    schema_file = ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(const.connection.pool.db_config)
  rescue => e
    warn("Could not locate schema: #{e.message}")
  end

  JSON.dump({
    columns: const.columns.map { |column| [column.name, column.type] },
    schema_file: schema_file,
  })
end

running = true # T.let(true, T::Boolean)
while running
  headers = $stdin.gets("\r\n\r\n")
  request = $stdin.read(headers[/Content-Length: (\d+)/i, 1].to_i)

  json = JSON.parse(request, symbolize_names: true)
  request_method = json.fetch(:method)
  params = json[:params]

  response_json = nil
  case request_method
  when "shutdown"
    running = false
  when "models"
    model_name = params.fetch(:name) # "User" # TODO: fix
    response_json = resolve_database_info_from_model(model_name).to_json
    $stdout.write("Content-Length: #{response_json.length}\r\n\r\n#{response_json}")
  end
end
