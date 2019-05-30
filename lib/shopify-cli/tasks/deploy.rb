require 'json'
require 'fileutils'
require 'shopify_cli'

module ShopifyCli
  module Tasks
    class Deploy < ShopifyCli::Task
      DOWNLOAD_URLS = {
        mac: 'https://cli-assets.heroku.com/heroku-darwin-x64.tar.gz',
      }
      TIMEOUT = 10

      def call(ctx)
        @ctx = ctx
        start
      end

      def start
        spin_group = CLI::UI::SpinGroup.new
        spin_group.add('Heroku CLI') do |spinner|
          heroku_install(spinner)
        end
        spin_group.add('Git') do |spinner|
          git_install(spinner)
          git_init(spinner)
        end
        spin_group.wait

        heroku_login
        heroku_select_app
        heroku_select_branch
      end

      def stop
        # no op
      end

      private

      def git_init(spinner)
        output, status = @ctx.capture2e('git', 'status')
        unless status.exitstatus == 0
          output, status = @ctx.capture2e('git', 'init')
        end

        return spinner.update_title('Git repo initiated') if status.exitstatus == 0

        raise 'Git repo is not initiated'
      end

      def git_install(spinner)
        output, status = @ctx.capture2e('git', '--version')
        return spinner.update_title('Git installed') if status.exitstatus == 0

        raise 'Git is not installed'
      end

      def heroku_app
        return nil if heroku_git_remote.nil?
        app = heroku_git_remote
        app = app.split('/').last
        app = app.split('.').first
        app
      end

      def heroku_command_path
        "#{File.join(ShopifyCli::ROOT, 'heroku', 'bin', 'heroku')}"
      end

      def heroku_git_remote
        output, status = @ctx.capture2e('git', 'remote', 'get-url', 'heroku')
        status.exitstatus == 0 ? output : nil
      end

      def heroku_install(spinner)
        return spinner.update_title('Heroku CLI installed') if heroku_installed?

        spinner.update_title('Setting up Heroku CLI…')

        filename = URI.parse(DOWNLOAD_URLS[:mac]).path.split('/').last
        gz_dest = File.join(ShopifyCli::ROOT, filename)

        unless File.exist?(filename)
          spinner.update_title('Downloading Heroku CLI…')
          @ctx.system('curl', '-o', gz_dest, DOWNLOAD_URLS[:mac], chdir: ShopifyCli::ROOT)
        end

        spinner.update_title('Installing Heroku CLI…')
        @ctx.system('tar', '-xf', gz_dest, chdir: ShopifyCli::ROOT)
        FileUtils.rm(gz_dest)
        return spinner.update_title('Heroku CLI installed')
      end

      def heroku_installed?
        return false unless File.exist?(heroku_command_path)

        output_and_errors, status = @ctx.capture2e(heroku_command_path, '--version')
        status.exitstatus == 0
      end

      def heroku_login
        output, status = @ctx.capture2e(heroku_command_path, 'whoami')
        return @ctx.puts("{{green:✓}} Authenticated with Heroku as #{output}") if status.exitstatus == 0

        @ctx.system(heroku_command_path, 'login')
      end

      def heroku_select_app
        return @ctx.puts("{{green:✓}} Heroku app `#{heroku_app}` selected") unless heroku_app.nil?

        app_type = CLI::UI::Prompt.ask('No existing Heroku app found. What would you like to do?') do |handler|
          handler.option('Create a new Heroku app') { :new }
          handler.option('Specify an existing Heroku app') { :existing }
        end

        if app_type == :existing
          app_name = CLI::UI::Prompt.ask('What is your Heroku app’s name?')
          @ctx.system(heroku_command_path, 'git:remote', '-a', app_name)
        elsif app_type == :new
          output, status = @ctx.capture2e(heroku_command_path, 'create')
          if status == 0
            new_remote = output.split("\n").last.split("|").last.strip
            @ctx.system('git', 'remote', 'add', 'heroku', new_remote)
          end
        end

        # git/heroku complain if there is no remote named `origin`
        output, status = @ctx.capture2e('git', 'remote', 'get-url', 'origin')
        @ctx.system('git', 'remote', 'add', 'origin', heroku_git_remote) if status != 0 && !heroku_git_remote.nil?
      end

      def heroku_select_branch
        output, status = @ctx.capture2e('git', 'branch', '--list')

        if output == ''
          branches = ['master']
        else
          branches = output.split("\n").map { |branch| branch.strip.scan(/^\*? ?(.+)?$/).last.first }
        end

        if branches.length == 1
          branch_to_deploy = branches[0]
          @ctx.puts("{{green:✓}} Selected `#{branches[0]}` branch")
        else
          branch_to_deploy = CLI::UI::Prompt.ask('What branch would you like to deploy?') do |handler|
            branches.each do |branch|
              handler.option(branch) { branch }
            end
          end
        end

        output, status = @ctx.capture2e('git', 'push', '-u', 'heroku', "#{branch_to_deploy}:master", '--dry-run')

        if status != 0
          @ctx.puts("{{red:x}} Deploy failed. Have you committed anything to this branch?")
          @ctx.puts(output)
        else
          @ctx.system('git', 'push', '-u', 'heroku', "#{branch_to_deploy}:master")
        end
      end
    end
  end
end
