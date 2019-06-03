require 'shopify_cli'

module ShopifyCli
  module Tasks
    class Clone < ShopifyCli::Task
      def call(*args)
        repository = args.shift
        dest = args.shift
        CLI::UI::Frame.open("Cloning into #{dest}...") do
          git_progress('clone', '--single-branch', repository, dest)
        end
      end

      def git_progress(*git_command)
        CLI::UI::Progress.progress do |bar|
          percent = 0.0
          while percent <= 1
            percent += 0.05
            bar.tick(set_percent: percent)
            sleep 0.05
          end
          true
        end
      end
    end
  end
end
