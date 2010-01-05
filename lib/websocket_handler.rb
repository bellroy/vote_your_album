require 'sunshowers'

class WebsocketHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Sunshowers::Request.new(env)

    if req.ws?
      req.ws_handshake!
      WebsocketDispatcher.register req

      ws_io = req.ws_io
      ws_io.each { } # no-op
      req.ws_quit!

      [404, {}, []]
    else
      status, headers, body = @app.call(env)
      [status, headers, body]
    end
  end
end
