require 'clamp'

module Salt
  module CLT
    class CLI < Clamp::Command

      class AbstractCommand < Clamp::Command
        option [ '-c', '--config_file' ], 'CONFIG', 'Config file', default: Salt::CLT::Config::DEFAULT_CONFIG_FILE

        option '--version', :flag, 'show version' do
          puts Salt::CLT::VERSION
          exit(0)
        end
      end

      class ConsoleCommand < AbstractCommand
        def execute
          require 'pry-byebug'
          pry Salt
        end
      end

      class ExecCommand < AbstractCommand
        parameter('FUNCTION', 'Function to execute', required: true)
        parameter('ARGS', 'Function args', required: false)
        option([ '-t', '--target' ], 'TARGET', 'Target to execute function over', default: '*')

        def execute
          res = API.new.execute!(function, target, args)
          puts JSON.pretty_generate(res)
        end
      end

      class MainCommand < AbstractCommand
        subcommand %w(c console), 'Run a console', ConsoleCommand
        subcommand %w(e exec), 'Execute a command', ExecCommand
      end
    end
  end
end
