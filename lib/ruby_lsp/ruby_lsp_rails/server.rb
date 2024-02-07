# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "json"

module RubyLsp
  module Rails
    class << self
      VOID = T.let(Object.new, Object)

      extend T::Sig

      sig { params(model_name: String).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
      def resolve_database_info_from_model(model_name)
        const = ActiveSupport::Inflector.safe_constantize(model_name)
        return unless const && const < ActiveRecord::Base

        begin
          # TODO: check if we should be relying on this
          schema_file = ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(const.connection.pool.db_config)
        rescue => e
          warn("Could not locate schema: #{e.message}")
        end

        {
          columns: const.columns.map { |column| [column.name, column.type] },
          schema_file: schema_file,
        }
      end

      sig { void }
      def start
        $stdin.sync = true
        $stdout.sync = true

        running = T.let(true, T::Boolean)

        while running
          begin
            warn("*** in begin")
            headers = $stdin.gets("\r\n\r\n")
            warn("no headers") unless headers
            request = $stdin.read(headers[/Content-Length: (\d+)/i, 1].to_i)

            json = JSON.parse(request, symbolize_names: true)
            request_method = json.fetch(:method)
            params = json[:params]

            response = case request_method
            when "shutdown"
              running = false
              VOID
            when "models"
              model_name = params.fetch(:name)
              RubyLsp::Rails.resolve_database_info_from_model(model_name)
            else
              VOID
            end
            next if response == VOID

            warn(response)
            response_json = JSON.dump(response) # .to_json
            $stdout.write("Content-Length: #{response_json.length}\r\n\r\n#{response_json}")
          rescue => e
            warn(e.backtrace)
            raise
          end
        end
      end
    end
  end
end

RubyLsp::Rails.start
