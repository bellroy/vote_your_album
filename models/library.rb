class Library
  include DataMapper::Resource
  
  property :id, Serial
  property :volume, Integer
  
  has n, :albums
  has n, :voteable_albums
  has n, :played_albums
  
  has n, :songs
  
  class << self
    
    # -----------------------------------------------------------------------------------
    # Setup
    # -----------------------------------------------------------------------------------
    def lib; Library.first || Library.create end
    
    def update_albums
      MpdConnection.fetch_new_albums_with_artists(lib.albums.map { |a| [a.artist, a.name] }).each { |album|
        lib.albums.create :artist => album[0], :name => album[1] }
    end
    
    # -----------------------------------------------------------------------------------
    # Album methods
    # -----------------------------------------------------------------------------------
    def list; lib.albums.sort_by { |a| "#{a.artist} #{a.name}" } end
    def upcoming; lib.voteable_albums.sort_by { |a| [a.rating, Time.now.tv_sec - a.created_at.tv_sec] }.reverse end
    def current; playing? ? lib.played_albums.first : nil end
    def <<(album); lib.voteable_albums.create :album => album, :created_at => Time.now end

    # -----------------------------------------------------------------------------------
    # Playback methods
    # -----------------------------------------------------------------------------------    
    def playlist; lib.songs end
    def current_song; playlist.select { |song| song.playing }.first end
    def playing?; !!current_song end
    def volume; lib.volume end
    
    # -----------------------------------------------------------------------------------
    # MPD Callbacks
    # -----------------------------------------------------------------------------------
    def current_song_callback(mpd_song = nil)
      current_song.update_attributes(:playing => false) if playing?
      
      if mpd_song
        song = playlist.select { |song| song.artist == mpd_song.artist && song.title == mpd_song.title }.first
        song.update_attributes(:playing => true) if song
      else
        play_next
      end
    end
    def playlist_callback(version = 0)
      return if version == 0
      lib.songs.destroy!
      MpdConnection.execute(:playlist).each { |mpd_song| Song.create_from_mpd(lib, mpd_song) }
    end
    def volume_callback(volume); lib.update_attributes :volume => volume end
    
    # -----------------------------------------------------------------------------------
    # MPD interfacing methods
    # -----------------------------------------------------------------------------------
    def search(q)
      return list if q.nil? || q.empty?
      
      res = MpdConnection.find_albums_for(q)
      list.select { |album| res.include? album.name }
    end
    def play_next
      return unless next_album = upcoming.first
      
      lib.played_albums.create(:album => next_album.album) && next_album.destroy
      MpdConnection.play_album next_album.name
    end
    def force(ip)
      return unless current
      
      current.vote 1, ip
      play_next if current.remaining <= 0
    end
  end
end