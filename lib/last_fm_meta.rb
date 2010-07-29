class LastFmMeta
  include LastFm

  class << self
    def album_info(artist, album)
      get("/2.0", :query => {
        :method => "album.getinfo",
        :artist => artist,
        :album => album
      })["lfm"]["album"]
    rescue NoMethodError
      nil
    end
    def similar_artists(artist)
      artists = get("/2.0", :query => {
        :method => "artist.getinfo",
        :artist => artist
      })

      artists["lfm"]["artist"]["similar"]["artist"].map { |h| h["name"] }
    rescue NoMethodError
      []
    end
  end
end
