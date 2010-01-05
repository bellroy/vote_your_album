require 'sunshowers'

class WebsocketHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Sunshowers::Request.new(env)

    if req.ws?
      req.ws_handshake!

      ws_io = req.ws_io
      @app.configure do
        WebsocketIo.setup ws_io
      end

      ws_io.write "happy new year!"
      ws_io.each do |record|
        ws_io.write "message received: #{record}"
      end
      req.ws_quit!

      [404, {}, []]
    else
      status, headers, body = @app.call(env)
      [status, headers, body]
    end
  end
end
