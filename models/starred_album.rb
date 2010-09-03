class StarredAlbum
  include DataMapper::Resource

  property :user_id, Integer, :key => true
  property :album_id, Integer, :key => true

  belongs_to :user
  belongs_to :album
end
