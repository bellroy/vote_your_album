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
  json_status
end

def json_status
  current = (Library.current ? Library.current.to_hash(request.ip) : nil)
  { :volume => Library.volume, :current => current, :upcoming => Library.upcoming.map { |a| a.to_hash(request.ip) } }.to_json
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  haml :index
end
get "/list" do
  Library.list.map { |album| album.to_hash }.to_json
end
get "/search" do
  Library.search(params[:q]).map { |album| album.to_hash }.to_json
end

get "/status" do
  json_status
end

post "/add/:id" do |album_id|
  execute_on_album(:list, album_id) { |album| Library << album }
end
post "/up/:id" do |album_id|
  execute_on_album(:upcoming, album_id) { |album| album.vote 1, request.ip, true }
end
post "/down/:id" do |album_id|
  execute_on_album(:upcoming, album_id) { |album| album.vote -1, request.ip, true }
end
post "/force" do
  Library.force request.ip
  json_status
end

post "/control/:action" do |action|
  MpdConnection.execute action.to_sym
  json_status
end
post "/volume/:value" do |value|
  MpdConnection.volume = value.to_i
end
post "/play" do
  Library.play_next unless Library.playing?
  json_status
end