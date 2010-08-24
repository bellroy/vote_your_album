class MpdProxy
  @mpd = nil
  @server = nil
  @port = nil
  @callbacks = false

  @volume = 0
  @current_song = nil
  @total = 0
  @time = 0
  @random_tracks = 1

  class << self
    def setup(server, port, callbacks = false)
      @server, @port, @callbacks = server, port, callbacks

      @mpd = MPD.new(@server, @port)
      @mpd.register_callback method(:current_song=), MPD::CURRENT_SONG_CALLBACK
      @mpd.register_callback method(:volume=), MPD::VOLUME_CALLBACK
      @mpd.register_callback method(:time=), MPD::TIME_CALLBACK
      connect
    end

    def execute(action); mpd.send action end
    def find_songs_for(album); mpd.find "album", album end

    def volume; @volume end
    def volume=(value); @volume = value end
    def change_volume_to(value); mpd.volume = value end

    def playing?; !!current_song end
    def current_song; @current_song end
    def current_song=(song = nil)
      @current_song = song
      play_next unless song
    end

    def total
      @total
    end

    def time
      @time
    end

    def time=(elapsed, total)
      @total = total
      @time = total - elapsed
    end

    def clear_playlist
      @random_tracks = 1
      execute :clear
    end

    def play_next
      mpd.clear

      if nomination = Nomination.active.first
        Update.log "Playing '#{nomination.album}' (<i>#{nomination.user.real_name}</i>)", nomination, nomination.user
        @random_tracks = 1

      elsif (Time.now.utc + 36000).hour < 19
        nomination = Album.nominate_similar(Nomination.current.album, @random_tracks)

        Update.log "<i>Dr Random</i> selected '#{nomination.album}' (#{@random_tracks} tracks)", nomination
        @random_tracks += 1
      end

      if nomination
        nomination.update :status => "played", :played_at => Time.now
        nomination.songs.each { |song| mpd.add song.file }
        mpd.play
      end
    end

  protected

    def connect
      @mpd.connect @callbacks
    rescue SocketError
    end

    # check if we lost connection to the server
    def mpd
      connect unless @mpd.connected?
      @mpd
    end
  end
end