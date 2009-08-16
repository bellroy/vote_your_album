class Album
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 100
  property :name, String, :length => 100
  property :last_played_at, Time
  
  has n, :songs
  has n, :nominations
  
  default_scope(:default).update :order => [:artist, :name]
  
  def to_hash; { :id => id, :artist => artist, :name => name } end
  
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
    
    def current; first :order => :last_played_at.desc end
    def search(q)
      return all if q.nil? || q.empty?
      all :conditions => ["artist LIKE ? OR name LIKE ?", "%#{q}%", "%#{q}%"]
    end
    # def search(q)
    #   return list if q.nil? || q.empty?
    #   
    #   res = MpdProxy.find_albums_for(q)
    #   list.select { |album| res.include? album.name }
    # end
  end
end