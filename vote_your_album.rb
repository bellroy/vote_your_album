%w[rubygems sinatra json haml librmpd dm-core dm-aggregates].each { |lib| require lib }
%w[album song nomination vote user].each { |model| require "models/#{model}" }
require 'lib/mpd_proxy'

require 'lib/config'

# -----------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------
def execute_on_nomination(id, do_render = true, &block)
  nomination = Nomination.get(id.to_i)
  yield(nomination) if nomination
  do_render ? render_upcoming : ""
end

def json_status
  current = Nomination.current
  
  status = { :playing => MpdProxy.playing?, :volume => MpdProxy.volume }
  status = status.merge(:current_album => current.album.to_s, :current_song => MpdProxy.current_song,
    :time => to_time(MpdProxy.time), :down_votes_necessary => current.down_votes_necessary,
    :rateable => current.can_be_rated_by?(request.ip), :forceable => current.can_be_forced_by?(request.ip)
  ) if MpdProxy.playing?
  status.to_json
end

def render_upcoming(expanded = [])
  @nominations = Nomination.active
  haml :upcoming, :layout => false, :locals => { :expanded => expanded }
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
  def score_class(score); score > 0 ? "positive" : (score < 0 ? "negative" : "") end
  def album_attributes(nomination, i, is_owner, expanded)
    attr = { :ref => nomination.id }
    
    classes = ["album", "loaded", (i % 2 == 0 ? "even" : "odd")]
    classes << ["deleteable"] if is_owner
    classes << ["expanded"] if expanded.include?(nomination.id.to_s)
    attr.update :class => classes.join(" ")
    
    attr.update(:title => "TTL: #{to_time(nomination.ttl)}") if nomination.ttl
    attr
  end
  
  def to_time(seconds)
    time = []
    time << "%02d" % (seconds / 3600) if seconds >= 3600
    time << "%02d" % ((seconds % 3600) / 60)
    time << "%02d" % (seconds % 60)
    "-" + time.join(":")
  end
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  haml :index
end
get "/embed" do
  haml :index, :layout => :embed
end
get "/list/:type" do |list_type|
  Album.send(list_type).map { |a| a.to_hash Album.value_method_for(list_type) }.to_json
end
get "/search" do
  Album.search(params[:q]).map { |a| a.to_hash }.to_json
end
get "/upcoming" do
  render_upcoming params[:expanded] || []
end
get "/songs/:album" do |album_id|
  album = Album.get(album_id.to_i)
  haml :songs, :layout => false, :locals => { :songs => (album ? album.songs : []) }
end

get "/status" do
  json_status
end

post "/add/:id" do |album_id|
  album = Album.get(album_id.to_i)
  album.nominate(request.ip) if album
  render_upcoming
end
post "/up/:id" do |nomination_id|
  execute_on_nomination(nomination_id) { |nomination| nomination.vote 1, request.ip }
end
post "/down/:id" do |nomination_id|
  execute_on_nomination(nomination_id) { |nomination| nomination.vote -1, request.ip }
end
post "/remove/:id" do |nomination_id|
  execute_on_nomination(nomination_id) { |nomination| nomination.remove request.ip }
end
post "/add_song/:nomination_id/:id" do |nomination_id, song_id|
  execute_on_nomination(nomination_id) { |nomination| nomination.add song_id.to_i, request.ip }
end
post "/delete_song/:nomination_id/:id" do |nomination_id, song_id|
  execute_on_nomination(nomination_id) { |nomination| nomination.delete song_id.to_i, request.ip }
end
post "/force" do
  Nomination.current.force request.ip
  json_status
end
post "/rate/:value" do |value|
  Nomination.current.rate value.to_i, request.ip
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

post "/name" do
  user = User.get_or_create_by(request.ip)
  user.update(:name => params[:name]) if user
end
