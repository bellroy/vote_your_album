class MpdProxy
  @mpd = nil
  @volume = 0
  @current_song = nil
  @total = 0
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

    def play_next
      @mpd.clear

      if nomination = Nomination.active.first
        nomination.update :status => "played", :played_at => Time.now
        @random_tracks = 1

      elsif (Time.now.utc + 36000).hour < 19
        album = Album.get(rand(Album.count) + 1)
        nomination = album.nominations.new(:status => "played", :played_at => Time.now, :created_at => Time.now, :user_id => 0)

        songs = album.songs.dup
        (songs.size - @random_tracks).times { songs.delete_at(rand(songs.size)) } unless @random_tracks > songs.size
        songs.each { |song| nomination.songs << song }
        nomination.save

        @random_tracks += 1
      end

      if nomination
        nomination.songs.each { |song| @mpd.add song.file }
        @mpd.play
      end
    end
  end
end