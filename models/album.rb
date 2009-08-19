class Album
  include DataMapper::Resource
  
  VALUE_METHODS = { "most_listened" => :play_count, "most_popular" => :score, "top_rated" => :rating }
  
  property :id, Serial
  property :artist, String, :length => 200
  property :name, String, :length => 200
  
  has n, :songs
  has n, :nominations
  
  default_scope(:default).update :order => [:artist, :name]
  
  def play_count; nominations.played.size end
  def score; nominations.inject(0) { |sum, n| sum + n.score } end
  def rating
    ratings = nominations.map { |n| n.ratings }.flatten
    return 0 if ratings.empty?
    (ratings.inject(0.0) { |sum, r| sum + r.value } / ratings.size * 10).round / 10.0
  end
  
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
    
    { :most_listened => :play_count, :most_popular => :score, :top_rated => :rating }.each do |method, criteria|
      define_method method do
        all("nominations.status.not" => nil).uniq.select { |a| a.send(criteria) > 0 }.sort_by { |a| a.send(criteria) }.reverse
      end
    end
        
    def value_method_for(scope); VALUE_METHODS[scope] end
  end
end