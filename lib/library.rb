class Library
  @list, @next = [], []
  @song = ""
  
  class << self
    def setup
      @mpd = MPD.new("mpd", 6600)
      @mpd.register_callback self.method("current_song_callback"), MPD::CURRENT_SONG_CALLBACK
      @mpd.connect true
      
      index = 0
      Library.list = @mpd.albums.inject([]) { |list, a| index += 1; list << Album.new(index, a, 0) }
      current_song_callback @mpd.current_song
    end
    
    def list; @list.sort_by { |a| a.name } end
    def list=(list); @list = list end
    
    def next; @next.sort_by { |a| a.votes }.reverse end
    def <<(album); @next << album end
    
    def play_next
      return unless next_album = @next.shift
      
      @mpd.clear
      files = @mpd.find("album", next_album.name).sort_by { |f| f.track.to_i }
      files.each { |f| @mpd.add f.file }
      @mpd.play
    end
    
    def song; @song end
    def current_song_callback(new_song)
      @song = (new_song ? "#{new_song.artist} - #{new_song.title} (#{new_song.album})" : "")
      play_next if new_song.nil?
    end
  end
end

Album = Struct.new(:id, :name, :votes)
Album.class_eval do
  def vote(with); self.votes += with end
end