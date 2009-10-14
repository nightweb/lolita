require 'rack/utils'
module Middleware
  class FlashSessionCookie
    def initialize(app, session_key = '_session_id')
      @app = app
      @session_key = session_key
    end

    def call(env)
      if env['HTTP_USER_AGENT'] =~ /^(Adobe|Shockwave) Flash/
        req = Rack::Request.new(env)
        if Lolita.config.system(:flash_actions).include?(req.path) && !req.params[@session_key].nil?
          env['HTTP_COOKIE'] = "#{@session_key}=#{req.params[@session_key]}".freeze
        end
      end
      @app.call(env)
    end
  end
end