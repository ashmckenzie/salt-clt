require 'uri'
require 'openssl'
require 'net/http'

module Salt
  module CLT
    class API
      DEFAULT_MODE = 'local'

      def initialize(client_mode = DEFAULT_MODE)
        @client_mode = client_mode
      end

      def execute!(target, function, args)
        request(target, function, args)
      rescue Errors::HTTPUnauthorized
        clear_x_auth_token!
        request(target, function, args)
      end

      def lookup_job(job_id)
        jobs(job_id)
      rescue Errors::HTTPUnauthorized
        clear_x_auth_token!
        jobs(job_id)
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

        def jobs_url(job_id)
          '%s/jobs/%s' % [ $config.settings.api.url, job_id ]
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

        def request(target, function, args)
          login! unless auth_token
          uri = URI(base_url)
          data = { client: client_mode, tgt: target, expr_form: 'compound', fun: function }
          data['arg'] = args if args
          headers = { 'X-Auth-Token' => auth_token }
          http_post!(uri, data, headers)
        end

        def jobs(job_id)
          login! unless auth_token
          uri = URI(jobs_url(job_id))
          headers = { 'X-Auth-Token' => auth_token }
          http_get!(uri, headers)
        end

        def http_post!(uri, data, headers)
          req = Net::HTTP::Post.new(uri)
          req.set_form_data(data)
          http!(req, headers)
        end

        def http_get!(uri, headers)
          http!(Net::HTTP::Get.new(uri), headers)
        end

        def http!(req, headers)
          req['Accept'] = 'application/json'
          headers.each { |k, v| req[k] = v }
          use_ssl = (req.uri.scheme == 'https')
          options = { use_ssl: use_ssl, verify_mode: ssl_verify_mode }

          res = Net::HTTP.start(req.uri.host, req.uri.port, options) do |http|
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
