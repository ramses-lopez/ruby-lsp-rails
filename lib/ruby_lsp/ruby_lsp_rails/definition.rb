# typed: strict
# frozen_string_literal: true

module RubyLsp
  module Rails
    # ![Definition demo](../../definition.gif)
    #
    # The [definition
    # request](https://microsoft.github.io/language-server-protocol/specification#textDocument_definition) jumps to the
    # definition of the symbol under the cursor.
    #
    # Currently supported targets:
    # - Callbacks
    #
    # # Example
    #
    # ```ruby
    # before_action :foo # <- Go to definition on this symbol will jump to the method if it is defined in the same class
    # ```
    class Definition
      extend T::Sig
      include Requests::Support::Common

      sig do
        params(
          client: RunnerClient,
          response_builder: ResponseBuilders::CollectionResponseBuilder[Interface::Location],
          nesting: T::Array[String],
          index: RubyIndexer::Index,
          dispatcher: Prism::Dispatcher,
        ).void
      end
      def initialize(client, response_builder, nesting, index, dispatcher)
        @client = client
        @response_builder = response_builder
        @nesting = nesting
        @index = index

        dispatcher.register(self, :on_call_node_enter)
      end

      sig { params(node: Prism::CallNode).void }
      def on_call_node_enter(node)
        $stderr.puts "Definition#on_call_node_enter: #{node.message}"
        # return unless self_receiver?(node)

        message = node.message
        $stderr.puts "message: #{message}"

        return unless message

        message = "users_path"

        # if Support::Callbacks::ALL.include?(message)
        #   handle_callback(node)
        # els
        if message.match?(/^([a-z_]+)(_path|_url)$/) # check. what about digits?
          $stderr.puts "handle_rooute #{node.message}"
          handle_route(node)
        end
      end

      sig { params(node: Prism::CallNode).void }
      def handle_callback(node)
        arguments = node.arguments&.arguments
        return unless arguments&.any?

        arguments.each do |argument|
          name = case argument
          when Prism::SymbolNode
            argument.value
          when Prism::StringNode
            argument.content
          end

          next unless name

          collect_definitions(name)
        end
      end

      sig { params(node: T.untyped).void }
      def handle_route(node)
        $stderr.puts "node.message: #{node.message}"
        # route = ::Rails.application.routes.named_routes.get(:users) # node.message)

        file_path, line = @client.route_location("users_path").fetch(:location).split(":") # TODO: user node message)
        $stderr.puts "111 done"

        # TODO: don't need `end?`
        @response_builder << Interface::Location.new(
          uri: URI::Generic.from_path(path: file_path).to_s,
          range: Interface::Range.new(
            start: Interface::Position.new(line: Integer(line) - 1, character: 0),
            end: Interface::Position.new(line: Integer(line) - 1, character: 0),
          ),
        )
      end

      private

      sig { params(name: String).void }
      def collect_definitions(name)
        methods = @index.resolve_method(name, @nesting.join("::"))
        return unless methods

        methods.each do |target_method|
          location = target_method.location
          file_path = target_method.file_path

          @response_builder << Interface::Location.new(
            uri: URI::Generic.from_path(path: file_path).to_s,
            range: Interface::Range.new(
              start: Interface::Position.new(line: location.start_line - 1, character: location.start_column),
              end: Interface::Position.new(line: location.end_line - 1, character: location.end_column),
            ),
          )
        end
      end
    end
  end
end
