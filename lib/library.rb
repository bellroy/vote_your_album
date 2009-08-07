class Library
  @list, @next = [], []
  @song = ""
  @enabled = false
  
  class << self
    def setup
      @mpd = MPD.new("mpd", 6600)
      @mpd.register_callback self.method("current_song_callback"), MPD::CURRENT_SONG_CALLBACK
      @mpd.connect true
      
      index = 0
      Library.list = @mpd.albums.inject([]) do |new_list, a|
        index += 1
        album_song = nil
                      # begin
                      #   @mpd.find("album", a).first   # get the albums artist by searching for songs with the album name
                      # rescue
                      #   nil
                      # end
        new_list << Album.new(index, (album_song.is_a?(MPD::Song) ? album_song.artist : ""), a, 0)
      end
      
      current_song_callback @mpd.current_song
    rescue SocketError
    ensure
      @enabled = false
    end
    
    def enabled?; @enabled end
    
    def list; @list.sort_by { |a| "#{a.artist} #{a.name}" } end
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
      play_next if enabled? && new_song.nil?
    end
    
    def control(action)
      case action
        when :enable
          @enabled = true
          play_next if song == ""
        when :disable
          @enabled = false
        else
          @mpd.send action
      end
    end
    
    def search(q)
      return list if q.nil? || q.empty?
      
      res = %w[artist album title].inject([]) { |matches, type|
        matches += @mpd.search(type, q) }.map { |song| song.album }.uniq
      list.select { |album| res.include? album.name }
    rescue RuntimeError
      list
    end
  end
end

Album = Struct.new(:id, :artist, :name, :votes, :voted_by)
Album.class_eval do
  def initialize(*args); super; self.voted_by = [] end
  
  def vote(with, from)
    return if voted_by.include?(from)
    self.votes += with; self.voted_by << from
  end
  def can_be_voted_for_by?(it); !voted_by.include?(it) end
  
  def to_hash(it); { :id => id, :artist => artist, :name => name, :votes => votes, :votable => can_be_voted_for_by?(it) } end
end