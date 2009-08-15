# -----------------------------------------------------------------------------------
# Development environment
# -----------------------------------------------------------------------------------
configure :development do
  DataMapper.setup(:default, "mysql://localhost/vote_your_album_dev")
  MpdConnection.setup "mpd", 6600
end

# -----------------------------------------------------------------------------------
# Production environment
# -----------------------------------------------------------------------------------
configure :production do
  DataMapper.setup(:default, "mysql://localhost/vote_your_album_prod")
  MpdConnection.setup "mpd", 6600, true
end

# -----------------------------------------------------------------------------------
# General config
# -----------------------------------------------------------------------------------
FORCE_VOTES = 3 # number of votes necessary to force the next album
ELIMINATION_SCORE = -3 # (negative) score necessary so that a upcoming album is removed