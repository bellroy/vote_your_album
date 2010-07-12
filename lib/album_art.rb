require 'httparty'

class AlbumArt
  include HTTParty
  base_uri "http://ws.audioscrobbler.com"
  default_params :method => "album.getinfo",
                 :api_key => "46021e7f85a446b1097cfe618f10ce3a"

  def fetch(artist, album)
    album_info = self.class.get("/2.0", :query => { :artist => artist, :album => album })

    art_url = album_info["lfm"]["album"]["image"][2]
    return nil unless art_url.is_a?(String)

    art_url
  end
end
