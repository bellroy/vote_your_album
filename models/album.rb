class Album
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 200
  property :name, String, :length => 200
  
  has n, :songs
  has n, :nominations
  
  default_scope(:default).update :order => [:artist, :name]
  
  def nominated?; !nominations.empty? end
  def played?; !nominations.played.empty? end
  
  def nominate(ip)
    nomination = nominations.create(:status => "active", :created_at => Time.now, :user => User.get_or_create_by(ip))
    nomination.vote 1, ip
    
    songs.each { |song| nomination.songs << song }
    nomination.save
  end
    
  def to_s; "#{artist} - #{name}" end
  def to_hash; { :id => id, :artist => artist, :name => name } end
  
  class << self
    def update
      MpdProxy.execute(:albums).each do |album|
        next if first(:name => album)
        
        new_album = Album.new(:name => album)        
        songs = MpdProxy.find_songs_for(album)
        songs.each { |song| new_album.songs.new :track => song.track, :artist => song.artist, :title => song.title, :file => song.file }
        new_album.artist = get_artist_from(songs)        
        new_album.save
      end
    end
    
    def search(q)
      return all if q.nil? || q.empty?
      all :conditions => ["artist LIKE ? OR name LIKE ?", "%#{q}%", "%#{q}%"]
    end
    
    def nominated; all.select { |a| a.nominated? } end
    def never_nominated; all.reject { |a| a.nominated? } end
    def played; all.select { |a| a.played? } end
    
    def most_listened
      execute_sql <<-SQL
SELECT a.*, COUNT(n.id) AS value FROM albums a
INNER JOIN nominations n ON n.album_id = a.id
WHERE n.status = 'played'
GROUP BY a.id
ORDER BY value DESC
      SQL
    end
    def top_rated
      execute_sql <<-SQL
SELECT a.*, AVG(v.value) AS value FROM albums a
INNER JOIN nominations n ON n.album_id = a.id
INNER JOIN votes v ON v.nomination_id = n.id
WHERE v.type = 'rating'
GROUP BY a.id
ORDER BY value DESC
      SQL
    end
    def most_popular
      execute_sql <<-SQL
SELECT a.*, SUM(v.value) / COUNT(DISTINCT n.id) AS value FROM albums a
INNER JOIN nominations n ON n.album_id = a.id
INNER JOIN votes v ON v.nomination_id = n.id
WHERE v.type = 'vote' AND v.value > 0
GROUP BY a.id
ORDER BY value DESC
      SQL
    end
    def least_popular
      execute_sql <<-SQL
SELECT a.*, SUM(v.value) / COUNT(DISTINCT n.id) AS value FROM albums a
INNER JOIN nominations n ON n.album_id = a.id
INNER JOIN votes v ON v.nomination_id = n.id
WHERE v.type = 'vote' AND v.value < 0
GROUP BY a.id
ORDER BY value
      SQL
    end
  
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
    
    def execute_sql(sql); repository(:default).adapter.query sql end
  end
end
