class MpdConnection
  @mpd = nil
  
  class << self
    def setup
      @mpd = MPD.new("mpd", 6600)
      @mpd.register_callback Library.method(:current_song_callback), MPD::CURRENT_SONG_CALLBACK
      @mpd.connect true
    rescue SocketError
    end
    
    def fetch_albums_with_artists
      @mpd.albums.inject([]) do |list, album|
        artist =  begin
                    @mpd.find("album", album).first.artist
                  rescue
                    ""
                  end
        list << [artist, album]
      end
    end
    
    def execute(action); @mpd.send action end
    
    def play_album(album)
      @mpd.clear
      @mpd.find("album", album).sort_by { |f| f.track.to_i }.each { |f| @mpd.add f.file }
      @mpd.play
    end
    
    def find_albums_for(q)
      %w[artist album title].inject([]) { |matches, type| matches += @mpd.search(type, q) }.map { |song| song.album }.uniq
    rescue
      []
    end
  end
end