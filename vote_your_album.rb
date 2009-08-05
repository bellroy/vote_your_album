%w[rubygems sinatra json haml librmpd].each { |lib| require lib }

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
  { :song => Library.song, :next => Library.next.map { |a| a.to_hash(request.ip) } }.to_json
end

get "/add/:id" do |album_id|
  execute_on_album(album_id) { |album| Library << album }
end
get "/up/:id" do |album_id|
  execute_on_album(album_id) { |album| album.vote 1, request.ip }
end
get "/down/:id" do |album_id|
  execute_on_album(album_id) { |album| album.vote -1, request.ip }
end

get "/control/:action" do |action|
  Library.control action.to_sym
end