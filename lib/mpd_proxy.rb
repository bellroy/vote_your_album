class MpdProxy
  @mpd = nil
  @volume = 0
  @current_song = nil
  @time = 0
  @random_tracks = 1

  class << self
    def setup(server, port, callbacks = false)
      @mpd = MPD.new(server, port)
      @mpd.register_callback method(:current_song=), MPD::CURRENT_SONG_CALLBACK
      @mpd.register_callback method(:volume=), MPD::VOLUME_CALLBACK
      @mpd.register_callback method(:time=), MPD::TIME_CALLBACK
      @mpd.connect callbacks
    rescue SocketError
    end

    def execute(action); @mpd.send action end
    def find_songs_for(album); @mpd.find "album", album end

    def volume; @volume end
    def volume=(value); @volume = value end
    def change_volume_to(value); @mpd.volume = value end

    def playing?; !!current_song end
    def current_song; @current_song end
    def current_song=(song = nil)
      @current_song = song
      play_next unless song
    end

    def time; @time end
    def time=(elapsed, total); @time = total - elapsed end

    def play_next
      @mpd.clear

      songs = []
      if nomination = Nomination.active.first
        nomination.update :status => "played", :played_at => Time.now
        songs = nomination.songs

        @random_tracks = 1
      elsif Time.now.hour < 19
        album = Album.get(rand(Album.count) + 1)

        songs = album.songs
        (songs.size - @random_tracks).times { songs.delete_at(rand(songs.size)) } unless @random_tracks > songs.size

        @random_tracks += 1
      end

      songs.each { |song| @mpd.add song.file }
      @mpd.play unless songs.size == 0
    end
  end
end