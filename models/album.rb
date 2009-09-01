class Album
  include DataMapper::Resource
  
  VALUE_METHODS = { "most_listened" => :play_count, "top_rated" => :rating, "most_popular" => :score, "least_popular" => :negative_score }
  
  property :id, Serial
  property :artist, String, :length => 200
  property :name, String, :length => 200
  
  has n, :songs
  has n, :nominations
  has n, :votes, :through => :nominations, :type => "vote", :value.gt => 0
  has n, :negative_votes, :through => :nominations, :class_name => "Vote", :type => "vote", :value.lt => 0
  has n, :ratings, :through => :nominations, :class_name => "Vote", :type => "rating"
  
  default_scope(:default).update :order => [:artist, :name]
  
  def play_count; nominations.played.size end
  def score; votes.sum(:value) || 0 end
  def negative_score; (negative_votes.sum(:value) || 0) * -1 end
  def rating; ((ratings.avg(:value) || 0.0) * 10).round / 10.0 end
  
  def nominate(ip); self.nominations.create(:status => "active", :created_at => Time.now, :nominated_by => ip).vote 1, ip end
    
  def to_s; "#{artist} - #{name}" end
  def to_hash(value_method = nil); { :id => id, :artist => artist, :name => name, :value => (value_method ? send(value_method) : nil) } end
  
  class << self
    def update
      MpdProxy.execute(:albums).each do |album|
        next if first(:name => album)
        
        new_album = Album.new(:name => album)        
        songs = MpdProxy.find_songs_for(album)
        songs.each { |song| new_album.songs.build :track => song.track, :artist => song.artist, :title => song.title, :file => song.file }
        new_album.artist = get_artist_from(songs)        
        new_album.save
      end
    end
    
    def search(q)
      return all if q.nil? || q.empty?
      all :conditions => ["artist LIKE ? OR name LIKE ?", "%#{q}%", "%#{q}%"]
    end
    
    { :most_listened => :play_count, :top_rated => :rating, :most_popular => :score, :least_popular => :negative_score }.each do |method, criteria|
      define_method method do
        all(:links => [:nominations]).uniq.select { |a| a.send(criteria) > 0 }.sort_by { |a| a.send(criteria) }.reverse
      end
    end
        
    def value_method_for(scope); VALUE_METHODS[scope] end
  
  private
    
    def get_artist_from(songs)
      artists = songs.map { |song| song.artist }.compact
      shortest = artists.sort_by { |artist| artist.length }.first
      
      case
        when shortest.nil?
          ""
        when artists.select { |artist| artist =~ /\A#{Regexp.escape(shortest)}/ }.size >= (songs.size / 2.0)
          shortest
        else
          "VA"
      end
    end
  end
end