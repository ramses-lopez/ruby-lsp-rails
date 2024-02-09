# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "json"

module RubyLsp
  module Rails
    class Server
      VOID = Object.new

      extend T::Sig

      sig { params(model_name: String).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
      def resolve_database_info_from_model(model_name)
        const = ActiveSupport::Inflector.safe_constantize(model_name)
        unless const && const < ActiveRecord::Base && !const.abstract_class?
          return {
            result: nil,
          }
        end

        schema_file = ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(const.connection.pool.db_config)

        {
          result: {
            columns: const.columns.map { |column| [column.name, column.type] },
            schema_file: ::Rails.root + schema_file,
          },
        }
      rescue => e
        {
          error: e.message,
        }
      end

      sig { void }
      def start
        $stdin.sync = true
        $stdout.sync = true

        running = T.let(true, T::Boolean)

        while running
          headers = $stdin.gets("\r\n\r\n")
          request = $stdin.read(headers[/Content-Length: (\d+)/i, 1].to_i)

          json = JSON.parse(request, symbolize_names: true)
          request_method = json.fetch(:method)
          params = json[:params]

          response = case request_method
          when "shutdown"
            running = false
            VOID
          when "model"
            resolve_database_info_from_model(params.fetch(:name))
          else
            VOID
          end

          next if response == VOID

          json_response = response.to_json
          $stdout.write("Content-Length: #{json_response.length}\r\n\r\n#{json_response}")
        end
      end
    end
  end
end
