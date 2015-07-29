require 'clamp'

module Salt
  module CLT
    class CLI < Clamp::Command
      VALID_MODES = { local: %w{local}, local_async: %w{local_async async} }

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
        option([ '-m', '--mode' ], 'MODE', 'Target to execute function over', default: Salt::CLT::API::DEFAULT_MODE) do |mode|
          if VALID_MODES.values.flatten.include?(mode)
            VALID_MODES.detect { |k, v| v.include?(mode) }[0]
          else
            fail(ArgumentError, 'Valid modes are %s' % VALID_MODES.values.flatten.inspect)
          end
        end

        def execute
          res = API.new(mode).execute!(target, function, args)
          puts JSON.pretty_generate(res)
        end
      end

      class LookupJobCommand < AbstractCommand
        parameter('JOB_ID', 'Job ID', required: true)

        def execute
          res = API.new.lookup_job(job_id)
          puts JSON.pretty_generate(res)
        end
      end

      class MainCommand < AbstractCommand
        subcommand %w(c console), 'Run a console', ConsoleCommand
        subcommand %w(e exec), 'Execute a command', ExecCommand
        subcommand %w(lj lookup-job), 'Lookup a job', LookupJobCommand
      end
    end
  end
end
