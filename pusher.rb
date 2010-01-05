require 'rubygems'
require 'rack'
require 'lib/websocket_handler'

t1 = Thread.new do
  i = 0
puts "starting thread"
  loop do
    puts "push: #{i}"

    sleep 10
    next unless WebsocketHandler.connected?

    WebsocketHandler.write "message: #i"
    i += 1
  end
end
t1.join
puts "joined"
