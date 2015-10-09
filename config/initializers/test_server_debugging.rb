if defined?(WebConsole) && Rails.env=='test_server'
  class WebConsoleUserAccess
    def initialize(app)
      @app = app
    end
    def call(env)
      env['action_dispatch.show_detailed_exceptions'] = true
      status, headers, body = @app.call(env)
      unless env['warden'] && env['warden'].user.try(:admin?)
        env['web_console.exception'] = nil
        env['web_console.binding'] = nil
      end
      return [status, headers, body]
    end
  end
  Rails.application.middleware.insert_after WebConsole::Middleware, WebConsoleUserAccess
  Rails.application.config.web_console.development_only = false
end
