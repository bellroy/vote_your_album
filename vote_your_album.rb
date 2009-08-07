%w[rubygems sinatra json haml librmpd dm-core].each { |lib| require lib }
%w[models/library models/album models/voteable_album models/vote lib/mpd_connection].each { |model| require model }

# -----------------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------------
configure do
  MpdConnection.setup
end

configure :development do
  DataMapper.setup(:default, "mysql://localhost/vote_your_album_dev")
end

configure :production do
  DataMapper.setup(:default, {
    :adapter  => "mysql",
    :database => "vote_your_album_prod",
    :username => "album_vote",
    :password => "EhbwVkKD5OdNY",
    :host     => "mysql"
  })
end

# -----------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------
def execute_on_album(list, album_id, &block)
  album = Library.send(list).find { |a| a.id == album_id.to_i }
  yield(album) if album
  redirect "/"
end

def render_index_with_list(&block)
  @song, @list, @next = Library.current_song, yield, Library.upcoming
  haml :index
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  render_index_with_list { Library.list }
end
post "/search" do
  render_index_with_list { Library.search params[:q] }
end

get "/status" do
  { :song => Library.current_song, :next => Library.upcoming.map { |a| a.to_hash(request.ip) } }.to_json
end

get "/add/:id" do |album_id|
  execute_on_album(:list, album_id) { |album| Library << album }
end
get "/up/:id" do |album_id|
  execute_on_album(:upcoming, album_id) { |album| album.vote 1, request.ip }
end
get "/down/:id" do |album_id|
  execute_on_album(:upcoming, album_id) { |album| album.vote -1, request.ip }
end

get "/control/:action" do |action|
  MpdConnection.execute action.to_sym
  redirect "/"
end
get "/play" do
  Library.play_next
  redirect "/"
end