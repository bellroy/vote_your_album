%w[rubygems sinatra json haml librmpd].each { |lib| require lib }

require 'lib/library'
Library.setup if production?
# # -----------------------------------------------------------------------------------
# # Setup
# # -----------------------------------------------------------------------------------
# configure :production do
#   Library.setup
# end


# -----------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------
def execute_on_album(album_id, &block)
  album = Library.list.find { |a| a.id == album_id.to_i }
  yield(album) if album
  redirect "/"
end

def render_index_with_list(&block)
  @song, @list, @next = Library.song, yield, Library.next
  haml :index
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  render_index_with_list { Library.list }
end
post "/search" do
  render_index_with_list { Library.search(params[:q]) }
end

get "/status" do
  { :enabled => Library.enabled?, :song => Library.song, :next => Library.next.map { |a| a.to_hash(request.ip) } }.to_json
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
  redirect "/"
end