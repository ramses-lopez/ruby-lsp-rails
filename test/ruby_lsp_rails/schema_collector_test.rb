# typed: true
# frozen_string_literal: true

require "test_helper"

SCHEMA_FILE = <<~RUBY
ActiveRecord::Schema[7.1].define(version: 2023_12_09_114241) do
  create_table "cats", force: :cascade do |t|
  end

  create_table "dogs", force: :cascade do |t|
  end

  add_foreign_key "cats", "dogs"
end
RUBY

module RubyLsp
  module Rails
    class SchemaCollectorTest < ActiveSupport::TestCase
      test "store locations of models by parsing create_table calls" do
        collector = RubyLsp::Rails::SchemaCollector.new
        Prism.parse(SCHEMA_FILE).value.accept(collector)

        assert_equal(collector.tables.keys, ['Cat', 'Dog'])
      ensure
        # T.must(queue).close
      end
    end
  end
end
