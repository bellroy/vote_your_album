class AlbumArt
  include LastFm

  def initialize(artist, album)
    @artist, @album = artist, album
  end

  def fetch
    fetch_by_exact_match || fetch_with_search || fetch_for_artist
  end

protected

  def fetch_by_exact_match
    album_info = LastFmMeta.album_info(@artist, @album)

    extract_art do
      album_info["image"][2]
    end
  rescue NoMethodError
    nil
  end

  def fetch_with_search
    album_infos = self.class.get("/2.0", :query => {
      :method => "album.search",
      :album => @album
    })

    extract_art do
      album_infos["lfm"]["results"]["albummatches"]["album"][0]["image"][2]
    end
  rescue NoMethodError
    nil
  end

  def fetch_for_artist
    artist_infos = self.class.get("/2.0", :query => {
      :method => "artist.search",
      :artist => @artist
    })

    extract_art do
      artist_infos["lfm"]["results"]["artistmatches"]["artist"][0]["image"][2]
    end
  rescue NoMethodError
    nil
  end

private

  def extract_art
    art_url = yield
    return nil unless art_url.is_a?(String)

    art_url
  end
end
