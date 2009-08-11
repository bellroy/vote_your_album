%w[rubygems sinatra json haml librmpd dm-core].each { |lib| require lib }
%w[lib/belongs_to_album models/library models/album models/voteable_album models/played_album models/vote models/song].each { |model| require model }
require 'lib/mpd_connection'

require 'config'

# -----------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------
def execute_on_album(list, album_id, &block)
  album = Library.send(list).find { |a| a.id == album_id.to_i }
  yield(album) if album
  redirect "/"
end

def render_index_with_list(&block)
  @list = yield
  haml :index
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  render_index_with_list { Library.list }
end
get "/search" do
  render_index_with_list { Library.search params[:q] }
end

get "/status" do
  current = (Library.current ? Library.current.to_hash(request.ip) : nil)
  { :volume => Library.volume, :current => current, :upcoming => Library.upcoming.map { |a| a.to_hash(request.ip) } }.to_json
end

get "/add/:id" do |album_id|
  execute_on_album(:list, album_id) { |album| Library << album }
end
get "/up/:id" do |album_id|
  execute_on_album(:upcoming, album_id) { |album| album.vote 1, request.ip, true }
end
get "/down/:id" do |album_id|
  execute_on_album(:upcoming, album_id) { |album| album.vote -1, request.ip, true }
end
get "/force" do
  Library.force request.ip
  redirect "/"
end

post "/control/:action" do |action|
  MpdConnection.execute action.to_sym
  redirect "/"
end
post "/volume/:value" do |value|
  MpdConnection.volume = value.to_i
end
get "/play" do
  Library.play_next unless Library.playing?
  redirect "/"
end