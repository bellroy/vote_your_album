# -----------------------------------------------------------------------------------
# Database config
# -----------------------------------------------------------------------------------
configure :development do
  DataMapper.setup(:default, "mysql://localhost/vote_your_album_dev")
end

configure :production do
  DataMapper.setup(:default, {
    :adapter  => "mysql",
    :database => "vote_your_album_prod",
    :username => "album_vote",
    :password => "EhbwVkKD5OdNY",
    :host     => "mysql"
  })
end

# -----------------------------------------------------------------------------------
# MPD config
# -----------------------------------------------------------------------------------
configure do
  MpdConnection.setup "mpd", 6600
end

# -----------------------------------------------------------------------------------
# General config
# -----------------------------------------------------------------------------------
NECESSARY_FORCE_VOTES = 3 # number of votes necessary to force the next album