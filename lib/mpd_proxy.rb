class MpdProxy
  @mpd = nil
  @volume = 0
  @current_song = nil
  
  class << self
    def setup(server, port, callbacks = false)
      @mpd = MPD.new(server, port)
      @mpd.register_callback method(:current_song=), MPD::CURRENT_SONG_CALLBACK
      @mpd.register_callback method(:volume=), MPD::VOLUME_CALLBACK
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
    
    def play_next
      return unless nomination = Nomination.active.first
      
      @mpd.clear
      nomination.update_attributes :status => "played", :played_at => Time.now
      nomination.album.songs.each { |song| @mpd.add song.file }
      @mpd.play
    end
  end
end