require 'rubygems'
require 'sinatra'
require 'haml'
require 'librmpd'

require 'lib/library'

# -----------------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------------
configure do
  mpd = MPD.new('mpd', 6600)
  mpd.connect
  
  index = 0
  Library.list = mpd.albums.inject([]) { |list, a| index += 1; list << Album.new(index, a, 0) }
end


# -----------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------
helpers do
  def song(song)
    song ? "#{song.artist} - #{song.title} (#{song.album})" : ""
  end
end

def execute_on_album(album_id, &block)
  album = Library.list.find { |a| a.id == album_id.to_i }
  yield(album) if album
  redirect "/"
end

# -----------------------------------------------------------------------------------
# Filters
# -----------------------------------------------------------------------------------
before do
  @mpd = MPD.new('mpd', 6600)
  @mpd.connect
end


# -----------------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------------
get "/" do
  @current_song, @list, @next = @mpd.current_song, Library.list, Library.next
  haml :index
end

get "/current_song" do
  song(@mpd.current_song)
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
