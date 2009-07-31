require 'rubygems'
require 'sinatra'
require 'haml'
require 'librmpd'

require 'lib/library'

# -----------------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------------
configure do
  Library.setup
end


# -----------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------
def execute_on_album(album_id, &block)
  album = Library.list.find { |a| a.id == album_id.to_i }
  yield(album) if album
  redirect "/"
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  @song, @list, @next = Library.song, Library.list, Library.next
  haml :index
end

get "/status" do
  Library.song
end

get "/add/:id" do |album_id|
  execute_on_album(album_id) { |album| Library << album }
end
get "/up/:id" do |album_id|
  execute_on_album(album_id) { |album| album.vote 1 }
end
get "/down/:id" do |album_id|
  execute_on_album(album_id) { |album| album.vote -1 }
end

get "/control/:action" do |action|
  Library.control action.to_sym
end