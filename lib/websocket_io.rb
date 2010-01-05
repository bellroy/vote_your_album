class WebsocketIo
  @io = nil

  class << self
    def setup(io)
      @io = io
    end

    def write(message)
      if @io
        @io.write message
        p "Message pushed: #{message}"
      else
        p "Cannot write. Theres no IO object"
      end
    end
  end
end
