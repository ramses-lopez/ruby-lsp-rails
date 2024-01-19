# typed: strict
# frozen_string_literal: true

require "ruby_lsp/addon"

require_relative "rails_client"
require_relative "hover"
require_relative "code_lens"
require_relative "runner_client"
require "open3"

module RubyLsp
  module Rails
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { returns(RailsClient) }
      def client
        @client ||= T.let(RailsClient.new, T.nilable(RailsClient))
      end

      # sig { returns(RubyLsp::Rails::RunnerClient) }
      # def runner_client
      #   @runner_client ||= T.let(RunnerClient.new, T.nilable(RunnerClient))
      # end

      sig { override.params(message_queue: Thread::Queue).void }
      def activate(message_queue)
        # client.check_if_server_is_running!
        @runner_client ||= T.let(RunnerClient.new, T.nilable(RunnerClient))
      end

      sig { override.void }
      def deactivate
        T.must(@runner_client).shutdown
      end

      # Creates a new CodeLens listener. This method is invoked on every CodeLens request
      sig do
        override.params(
          uri: URI::Generic,
          dispatcher: Prism::Dispatcher,
        ).returns(T.nilable(Listener[T::Array[Interface::CodeLens]]))
      end
      def create_code_lens_listener(uri, dispatcher)
        CodeLens.new(uri, dispatcher)
      end

      sig do
        override.params(
          nesting: T::Array[String],
          index: RubyIndexer::Index,
          dispatcher: Prism::Dispatcher,
        ).returns(T.nilable(Listener[T.nilable(Interface::Hover)]))
      end
      def create_hover_listener(nesting, index, dispatcher)
        Hover.new(T.must(@runner_client), nesting, index, dispatcher)
      end

      sig { override.returns(String) }
      def name
        "Ruby LSP Rails"
      end
    end
  end
end
