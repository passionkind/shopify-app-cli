require 'shopify_cli'
require 'haikunator'
require 'pry'

module ShopifyCli
  module Commands
    class Create < ShopifyCli::Command
      # prerequisite_task :tunnel

      def call(args, _name)
        # binding.pry

        @thing = args.shift
        @name = args.shift

        # @ctx.puts("{{green:✓}} #{@thing}")
        # @ctx.puts("{{green:✓}} #{@name}")

        # return puts CLI::UI.fmt(self.class.help) unless @thing
        # return puts CLI::UI.fmt(self.class.help) unless @name

        if @thing == 'project' || @thing == 'app'
          api_client = CLI::UI::Prompt.ask('Which Shopify app is this project for?') do |handler|
            handler.option('Create a new Shopify app') { :new }
            handler.option('Vanessa’s Robot App') { nil }
            handler.option('Yard Sale') { nil }
          end
          @ctx.puts("{{green:✓}} New Shopify app “#{@name}” created")
          app_type = CLI::UI::Prompt.ask('What type of project would you like to scaffold?') do |handler|
            AppTypeRegistry.each do |identifier, type|
              handler.option(type.description) { identifier }
            end
          end
          AppTypeRegistry.build(app_type, @name, @ctx)
          ShopifyCli::Project.write(@ctx, app_type)
        elsif @thing == 'dev-store' || @thing == 'devstore' || @thing == 'store' || @thing == 'dev-shop' || @thing == 'devshop' || @thing == 'shop'
          app = File.read(File.join(@ctx.root, '.name')).strip
          shop = "#{Haikunator.haikunate}.myshopify.com"

          @ctx.system("echo \"#{shop}\" >> #{@ctx.root}/.shop")

          @ctx.puts("{{green:✓}} New Shopify dev store “#{shop}” created")
          @ctx.puts("{{green:✓}} App “#{app}” installed on #{shop}")
        end
      end

      def self.help
        <<~HELP
          Bootstrap an app.
          Usage: {{command:#{ShopifyCli::TOOL_NAME} create <appname>}}
        HELP
      end
    end
  end
end
