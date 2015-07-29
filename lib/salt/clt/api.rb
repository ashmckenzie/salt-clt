require 'uri'
require 'openssl'
require 'net/http'

module Salt
  module CLT
    class API
      DEFAULT_MODE = 'local'

      def execute!(function, target, args)
        request(function, target, args)
      def initialize(client_mode = DEFAULT_MODE)
        @client_mode = client_mode
      end

      rescue Errors::HTTPUnauthorized
        clear_x_auth_token!
        request(function, target, args)
      end

      private

        attr_reader :client_mode

        def login_params
          @login_params ||= begin
            {
              username: $config.settings.account.username,
              password: $config.settings.account.password,
              eauth:    'pam'
            }
          end
        end

        def base_url
          $config.settings.api.url
        end

        def login_url
          '%s/login' % $config.settings.api.url
        end

        def clear_x_auth_token!
          $config.settings.account.x_auth_token = nil
          $config.save!
        end

        def login!
          uri = URI(login_url)
          res = http_post!(uri, login_params)
          token = res['return'].first['token']
          $config.settings.account.x_auth_token = token
          $config.save!
        rescue Errors::HTTPUnauthorized
          fail('Incorrect password')
        end

        def auth_token
          $config.settings.account.x_auth_token
        end

        def ssl_verify_mode
          @ssl_verify_mode ||= $config.settings.api.ignore_ssl ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        end

        def request(function, target, args)
          login! unless auth_token
          uri = URI(base_url)
          data = { client: 'local', tgt: target, expr_form: 'compound', fun: function }
          data['arg'] = args if args
          headers = { 'X-Auth-Token' => auth_token }
          http_post!(uri, data, headers)
        end

        def http_post!(uri, data, headers={})
          req = Net::HTTP::Post.new(uri)
          req.set_form_data(data)
          req['Accept'] = 'application/json'
          headers.each { |k, v| req[k] = v }
          use_ssl = (uri.scheme == 'https')
          options = { use_ssl: use_ssl, verify_mode: ssl_verify_mode }

          res = Net::HTTP.start(uri.host, uri.port, options) do |http|
            http.read_timeout = 500
            http.request(req)
          end

          case res
          when Net::HTTPOK
            JSON.parse(res.body)
          when Net::HTTPUnauthorized
            fail(Errors::HTTPUnauthorized)
          else
            fail("Request failed - '%s'" % res.body)
          end
        end

    end
  end
end
