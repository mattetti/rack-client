module Rack
  module Client
    class FollowRedirects
      def initialize(app)
        @app = app
      end

      def call(env, &b)
        if block_given?
          async(env, &b)
        else
          sync(env)
        end
      end

      def async(env, &block)
        @app.call(env) do |response|
          if response.redirect?
            follow_redirect(response, env, &block)
          else
            yield response
          end
        end
      end

      def sync(env, &block)
        response = @app.call(env)
        response.redirect? ? follow_redirect(response, env, &block) : response
      end

      def follow_redirect(response, env, &block)
        call(next_env(response, env), &block)
      end

      def next_env(response, env)
        env, uri = env.dup, URI.parse(response['Location'])

        env.update 'PATH_INFO'      => uri.path
        env.update 'REQUEST_METHOD' => 'GET'

        env
      end
    end
  end
end