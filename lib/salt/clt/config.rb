require 'dotenv'
require 'hashie'

module Salt
  module CLT
    class Config

      DEFAULT_CONFIG_FILE = File.join(ENV['HOME'], '.salt_env')

      def initialize(config_file = DEFAULT_CONFIG_FILE)
        @config_file = config_file
        Dotenv.load(config_file)
      end

      def settings
        @settings ||= Hashie::Mash.new(hash)
      end

      def save!
        File.open(config_file, 'w') { |f| f.write(contents) }
      end

      private

        attr_reader :config_file

        def contents
          <<_EOS
SALT_URL='#{settings.api.url}'
SALT_IGNORE_SSL=#{settings.api.ignore_ssl}
SALT_USERNAME='#{settings.account.username}'
SALT_PASSWORD='#{settings.account.password}'
SALT_X_AUTH_TOKEN='#{settings.account.x_auth_token}'
_EOS
        end

        def hash
          {
            api: {
              url:          ENV['SALT_URL']          || missing_env!('SALT_URL'),
              ignore_ssl:   ENV['SALT_IGNORE_SSL']   || false
            },
            account: {
              username:     ENV['SALT_USERNAME'] || missing_env!('SALT_USERNAME'),
              password:     ENV['SALT_PASSWORD'] || missing_env!('SALT_PASSWORD'),
              x_auth_token: ENV['SALT_X_AUTH_TOKEN']
            }
          }
        end

        def missing_env!(env)
          fail("Missing ENV['%s'], add to %s" % [ env, config_file ])
        end

    end
  end
end
