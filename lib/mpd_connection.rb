class MpdConnection
  @mpd = nil
  
  class << self
    def setup(server, port, callbacks = false)
      @mpd = MPD.new(server, port)
      @mpd.register_callback Library.method(:current_song_callback), MPD::CURRENT_SONG_CALLBACK
      @mpd.register_callback Library.method(:volume_callback), MPD::VOLUME_CALLBACK
      @mpd.connect callbacks
    rescue SocketError
    end
    
    def fetch_new_albums_with_artists(existing)
      songs = @mpd.songs.select { |song| song.artist }.map { |song| [song.artist, song.album] }.sort_by { |song| song[0] }.uniq
      @mpd.albums.inject([]) do |list, album|
        artist = (songs.any? { |s| s[1] == album } ? songs.select { |song| song[1] == album }.first[0] : "")
        next if existing.include? [artist, album]
        list << [artist, album]
      end || []
    end
    
    def execute(action); @mpd.send action end
    def volume=(value); @mpd.volume = value end
    
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