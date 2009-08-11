class Song
  include DataMapper::Resource
  
  property :id, Serial
  property :track, String, :length => 10
  property :artist, String, :length => 100
  property :title, String, :length => 100
  
  belongs_to :library
  belongs_to :album
  
  def self.create_from_mpd(mpd_song)
    album = (Library.current ? Library.current.album : nil)
    create :track => mpd_song.track, :artist => mpd_song.artist, :title => mpd_song.title, :album => album
  end
end