require 'rubygems'
require 'sinatra'
require 'haml'
require 'librmpd'

helpers do
  def song(song)
    "#{song.artist} - #{song.title} (#{song.album})"
  end
end

before do
  @mpd = MPD.new('mpd', 6600)
  @mpd.connect
end

get "/" do
  @current_song = @mpd.current_song
  @albums = @mpd.albums
  
  haml :index
end

get "/current_song" do
  song(@mpd.current_song)
end