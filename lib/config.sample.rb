# -----------------------------------------------------------------------------------
# Development environment
# -----------------------------------------------------------------------------------
configure :development do
  DataMapper.setup(:default, "mysql://localhost/vote_your_album_dev")
  MpdProxy.setup "mpd", 6600
end

# -----------------------------------------------------------------------------------
# Production environment
# -----------------------------------------------------------------------------------
configure :production do
  DataMapper.setup(:default, "mysql://localhost/vote_your_album_prod")
  MpdProxy.setup "mpd", 6600, true
end