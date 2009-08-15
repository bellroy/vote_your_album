class Album
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 100
  property :name, String, :length => 100
  property :last_played_at, Time
  
  # belongs_to :library
  has n, :songs
  has n, :nominations
  
  def to_hash; { :artist => (artist || ""), :name => name } end
  def id_hash; to_hash.merge :id => id end
  
  class << self
    
    def update
      songs = MpdConnection.execute(:songs)
      MpdConnection.execute(:albums).each do |album|
        next if first(:name => album)
        
        new_album = Album.build(:name => album)
        songs.select { |song| song.album == album }.each { |song|
          new_album.songs.build :track => song.track, :artist => song.artist, :title => song.title, :file => song.file }
        new_album.artist = new_album.songs.map { |song| song.artist }.compact.sort_by { |artist| artist.length }.first || ""
        new_album.save
      end
    end
  end
end