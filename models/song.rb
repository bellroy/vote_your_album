class Song
  include DataMapper::Resource
  
  property :id, Serial
  property :track, String, :length => 10
  property :artist, String, :length => 100
  property :title, String, :length => 100
  property :playing, Boolean
  
  belongs_to :library
  belongs_to :album
  
  def self.create_from_mpd(library, mpd_song)
    create :library => library, :track => mpd_song.track, :artist => mpd_song.artist, :title => mpd_song.title, :album => Library.current
  end
end