# typed: true
# frozen_string_literal: true

# https://github.com/Shopify/team-ruby-dx/issues/1106

# How to start:
#   bin/rails runner test/dummy/lib/lsp.rb
#
# Make a request to:
#   http://localhost:8000/ruby_lsp_rails/models/User

class Lsp
  class << self
    BASE_PATH = "/ruby_lsp_rails/" # will change later - using for testing using the current extension

    def start
      require "webrick"

      server = WEBrick::HTTPServer.new(Port: 8000)
      server.mount_proc("/") do |req, res|
        model_name = req.path.gsub(BASE_PATH + "models/", "")
        const = ActiveSupport::Inflector.safe_constantize(model_name)
        # TODO: check if this picks up new tables without having to restart
        if const && const < ActiveRecord::Base
          begin
            schema_file = ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(const.connection.pool.db_config)
          rescue => e
            warn("Could not locate schema: #{e.message}")
          end

          body = JSON.dump({
            columns: const.columns.map { |column| [column.name, column.type] },
            schema_file: schema_file,
          })
          res.body = body
        else
          res.body = "not found-#{model_name}"
        end
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
