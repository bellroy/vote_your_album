require 'rubygems'
require 'sinatra'
require 'haml'
require 'librmpd'

require 'lib/library'


# -----------------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------------
Album = Struct.new(:id, :name, :votes)

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
  album = Library.list.find { |a| a.id == album_id.to_i }
  Library << album if album
  redirect "/"
end
