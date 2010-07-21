class LastFmMeta
  include LastFm

  class << self
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
