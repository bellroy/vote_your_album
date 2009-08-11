class Library
  include DataMapper::Resource
  
  property :id, Serial
  property :current_song, String, :length => 200
  property :volume, Integer
  
  has n, :albums
  has n, :voteable_albums
  has n, :played_albums
  
  class << self
    def lib; Library.first || Library.create end
    
    def update_albums
      MpdConnection.fetch_new_albums_with_artists(lib.albums.map { |a| [a.artist, a.name] }).each { |album|
        lib.albums.create :artist => album[0], :name => album[1] }
    end
    
    def volume; lib.volume end
    def list; lib.albums.sort_by { |a| "#{a.artist} #{a.name}" } end
    def upcoming; lib.voteable_albums.sort_by { |a| [a.rating, Time.now.tv_sec - a.created_at.tv_sec] }.reverse end
    def current; playing? ? lib.played_albums.first : nil end
    def <<(album); lib.voteable_albums.create :album => album, :created_at => Time.now end
    
    def search(q)
      return list if q.nil? || q.empty?
      
      res = MpdConnection.find_albums_for(q)
      list.select { |album| res.include? album.name }
    end
    
    def current_song_callback(song = nil)
      lib.update_attributes :current_song => (song ? "#{song.artist} - #{song.title} (#{song.album})" : nil)
      play_next unless Library.playing?
    end
    def volume_callback(volume); lib.update_attributes :volume => volume end
    
    def playing?; !!lib.current_song end
    def play_next
      return unless next_album = upcoming.first
      
      MpdConnection.play_album next_album.name
      lib.played_albums.create(:album => next_album.album) && next_album.destroy
    end
    def force(ip)
      return unless current
      
      current.vote 1, ip
      play_next if current.remaining <= 0
    end
  end
end