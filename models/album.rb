class Album
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 200
  property :name, String, :length => 200
  
  has n, :songs
  has n, :nominations
  
  default_scope(:default).update :order => [:artist, :name]
  
  def to_s; "#{artist} - #{name}" end
  
  class << self
    def update
      songs = MpdProxy.execute(:songs)
      MpdProxy.execute(:albums).each do |album|
        next if first(:name => album)
        
        new_album = Album.new(:name => album)        
        songs.select { |song| song.album == album }.each { |song|
          new_album.songs.build :track => song.track, :artist => song.artist, :title => song.title, :file => song.file }
        new_album.artist = new_album.songs.map { |song| song.artist }.compact.sort_by { |artist| artist.length }.first || ""
        new_album.save
      end
    end
    
    def search(q)
      return all if q.nil? || q.empty?
      all :conditions => ["artist LIKE ? OR name LIKE ?", "%#{q}%", "%#{q}%"]
    end
    
    def most_listened; all("nominations.status" => "played").sort_by { |album| album.nominations.played.size }.reverse end
    def most_popular; all("nominations.score.gt" => 0).sort_by { |album| album.nominations.inject(0) { |sum, n| sum + n.score } }.reverse end
  end
end