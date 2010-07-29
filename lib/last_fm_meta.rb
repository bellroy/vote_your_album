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

    def tags(info)
      [info["toptags"]["tag"]].flatten.map { |t| t["name"] }
    rescue NoMethodError
      []
    end

    def similar_artists(artist)
      get("/2.0", :query => {
        :method => "artist.getinfo",
        :artist => artist
      })["lfm"]["artist"]["similar"]["artist"].map { |h| h["name"] }
    rescue NoMethodError
      []
    end
  end
end
