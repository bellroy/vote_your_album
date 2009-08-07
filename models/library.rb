class Library
  include DataMapper::Resource
  
  property :id, Serial
  property :current_song, String, :length => 200
  
  has n, :albums
  has n, :voteable_albums
  
  class << self
    def lib; Library.first || Library.create end
    
    def fetch_albums
      lib.albums.destroy!
      MpdConnection.fetch_albums_with_artists.each { |album| lib.albums.create :artist => album[0], :name => album[1] }
    end
    
    def current_song; lib.current_song end
    def list; lib.albums.sort_by { |a| "#{a.artist} #{a.name}" } end
    def upcoming; lib.voteable_albums.sort_by { |a| a.votes }.reverse end
    def <<(album); lib.voteable_albums.create :artist => album.artist, :name => album.name end
    
    def search(q)
      return list if q.nil? || q.empty?
      
      res = MpdConnection.find_albums_for(q)
      list.select { |album| res.include? album.name }
    end
    
    def current_song_callback(song)
      lib.update_attributes :current_song => (song ? "#{song.artist} - #{song.title} (#{song.album})" : "")
      play_next unless song
    end
    
    def play_next
      return unless next_album = upcoming.first
      
      MpdConnection.play_album next_album.name
      next_album.destroy
    end
  end
end