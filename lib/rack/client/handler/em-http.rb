require 'em-http'

module Rack
  module Client
    module Handler
      class EmHttp
        include Rack::Client::DualBand

        def initialize(url)
          @uri = URI.parse(url)
        end

        def sync_call(env)
          raise("Synchronous API is not supported for EmHttp Handler") unless block_given?
        end

        def async_call(env)
          request = Rack::Request.new(env)

          EM.schedule do
            em_http = connection(request.path).send(request.request_method.downcase, request_options(request))
            em_http.callback do
              yield parse(em_http).finish
            end

            em_http.errback do
              yield parse(em_http).finish
            end
          end
        end

        def connection(path)
          @connection ||= EventMachine::HttpRequest.new((@uri + path).to_s)
        end

        def request_options(request)
          options = {}

          if request.body
            options[:body] = case request.body
                             when Array     then request.body.to_s
                             when StringIO  then request.body.string
                             when IO        then request.body.read
                             when String    then request.body
                             end
          end

          options
        end

        def parse(em_http)
          body = em_http.response.empty? ? [] : StringIO.new(em_http.response)
          Response.new(em_http.response_header.status, Headers.new(em_http.response_header).to_http, body)
        end

        def normalize_headers(em_http)
          headers = em_http.response_header

          headers['LOCATION'] = URI.parse(headers['LOCATION']).path if headers.include?('LOCATION')

          headers
        end
      end
    end
  end
end
