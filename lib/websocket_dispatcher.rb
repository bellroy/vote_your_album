class WebsocketDispatcher
  @req_list = []

  class << self
    def register(req)
      @req_list << req
    end

    def write(message)
      closed = []

      @req_list.each do |req|
        begin
          req.ws_io.write message
        rescue Exception => e
          req.ws_quit!
          closed << req
        end
      end

      closed.each { |req| @req_list.delete req }
    end

    def write_json(hash)
      write hash.to_json
    end
  end
end
