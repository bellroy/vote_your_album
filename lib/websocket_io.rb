class WebsocketIo
  @req_list = []

  class << self
    def register(req)
      @req_list << req
    end

    def write(message)
      p "trying to push, sockets: #{@req_list.size}"
      @req_list.each do |req|
        begin
          req.ws_io.write message
          p "Message '#{message}' pushed"
        rescue Exception => e
          req.ws_quit!
          p "error while writing to #{req.inspect}: #{e}"
        end
      end
    end
  end
end
