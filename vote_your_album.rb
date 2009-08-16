%w[rubygems sinatra json haml librmpd dm-core].each { |lib| require lib }
%w[models/album models/song models/nomination models/vote].each { |model| require model }
require 'lib/mpd_proxy'

require 'config'

# -----------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------
def execute_on_nomination(id, &block)
  nomination = Nomination.get(id.to_i)
  yield(nomination) if nomination
  json_status
end

def json_status
  current = (Album.current ? Album.current.to_hash : nil)
  { :volume => MpdProxy.volume, :current => current, :upcoming => Nomination.all.map { |n| n.to_hash(request.ip) } }.to_json
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  haml :index
end
get "/list" do
  Album.all.map { |album| album.to_hash }.to_json
end
get "/search" do
  Album.search(params[:q]).map { |album| album.to_hash }.to_json
end

get "/status" do
  json_status
end

post "/add/:id" do |album_id|
  album = Album.get(album_id.to_i)
  album.nominations.create(:status => "active", :created_at => Time.now, :nominated_by => request.ip) if album
  json_status
end
post "/up/:id" do |nomination_id|
  execute_on_nomination(nomination_id) { |nomination| nomination.vote 1, request.ip }
end
post "/down/:id" do |nomination_id|
  execute_on_nomination(nomination_id) { |nomination| nomination.vote -1, request.ip }
end
post "/force" do
  # Library.force request.ip
  json_status
end

post "/control/:action" do |action|
  MpdProxy.execute action.to_sym
  json_status
end
post "/volume/:value" do |value|
  MpdProxy.change_volume_to value.to_i
end
post "/play" do
  MpdProxy.play_next unless MpdProxy.playing?
  json_status
end