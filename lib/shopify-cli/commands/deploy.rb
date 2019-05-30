# frozen_string_literal: true

require 'shopify_cli'

module ShopifyCli
  module Commands
    class Deploy < ShopifyCli::Command
      # subcommands :start, :stop

      def call(args, _name)
        subcommand = args.shift
        task = ShopifyCli::Tasks::Deploy.new
        task.call(@ctx)
        # case subcommand
        # when 'start'
        #   task.call(@ctx)
        # when 'stop'
        #   task.stop(@ctx)
        # else
        #   puts CLI::UI.fmt(self.class.help)
        # end
      end

      def self.help
        <<~HELP
          Deploy app to Heroku
          Usage: {{command:#{ShopifyCli::TOOL_NAME} deploy}}
        HELP
      end
    end
  end
end
