class Album
  include DataMapper::Resource

  property :id, Serial
  property :artist, String, :length => 200
  property :name, String, :length => 200
  property :art, String, :length => 255

  has n, :songs
  has n, :nominations
  has n, :active_nominations, :model => "Nomination", :status => "active"

  default_scope(:default).update :order => [:artist, :name]

  def nominated?
    !nominations.empty?
  end

  def currently_nominated?
    !active_nominations.empty?
  end

  def played?
    !nominations.played.empty?
  end

  def nominate(current_user)
    return if currently_nominated?

    nomination = nominations.create(:status => "active", :created_at => Time.now, :user => current_user)
    Update.log "<i>#{current_user.real_name}</i> nominated '#{to_s}'"

    nomination.vote 1, current_user
    songs.each { |song| nomination.songs << song }
    nomination.save
  end

  def fetch_album_art
    self.art = AlbumArt.new(artist, name).fetch
    save
  end

  def to_s
    "#{artist} - #{name}"
  end

  def to_hash
    { :id => id, :artist => artist, :name => name, :art => art }
  end

  class << self
    def update
      MpdProxy.execute(:albums).each do |album|
        album.gsub!(/"/, '')
        next if first(:name => album)

        songs = MpdProxy.find_songs_for(album).reject { |song| Song.first(:title => song.title) }
        return if songs.empty?

        new_album = Album.new(:name => album)
        songs.each do |song|
          new_album.songs.new :track => song.track.to_i,
                              :artist => song.artist,
                              :title => song.title,
                              :length => song.time.to_i,
                              :file => song.file
        end

        new_album.artist = get_artist_from(songs)
        new_album.fetch_album_art
        new_album.save

        print "."
      end
    end

    def search(q)
      return all if q.nil? || q.empty?
      all :conditions => ["artist LIKE ? OR name LIKE ?", "%#{q}%", "%#{q}%"]
    end

    def nominated
      all.select { |a| a.nominated? }
    end

    def never_nominated
      all.reject { |a| a.nominated? }
    end

    def played
      all.select { |a| a.played? }
    end

    def random
      [get(rand(count) + 1)]
    end

    def most_listened
      execute_sql "COUNT(DISTINCT n.id)", "n.status = 'played'"
    end

    def most_popular
      execute_sql "SUM(v.value) / COUNT(DISTINCT n.id)", "v.type = 'vote' AND v.value > 0"
    end

    def least_popular
      execute_sql "SUM(v.value) / COUNT(DISTINCT n.id)", "v.type = 'vote' AND v.value < 0", "ASC"
    end

  private

    def get_artist_from(songs)
      artists = songs.map { |song| song.artist }.compact
      shortest = artists.sort_by { |artist| artist.length }.first

      case
        when shortest.nil?
          "Unknown"
        when artists.select { |artist| artist =~ /\A#{Regexp.escape(shortest)}/ }.size >= (songs.size / 2.0)
          shortest
        else
          "VA"
      end
    end

    def execute_sql(value, conditions, sort = "DESC")
      repository(:default).adapter.query <<-SQL
SELECT a.*, #{value} AS value FROM albums a
INNER JOIN nominations n ON n.album_id = a.id
INNER JOIN votes v ON v.nomination_id = n.id
WHERE #{conditions}
GROUP BY a.id
ORDER BY value #{sort}
      SQL
    end
  end
end
