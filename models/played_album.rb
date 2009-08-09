class PlayedAlbum
  include DataMapper::Resource
  include BelongsToAlbum
  
  property :id, Serial
  
  default_scope(:default).update(:order => [:id.desc])
  
  def to_hash(ip); { :rating => rating, :votable => can_be_voted_for_by?(ip) }.merge(album.to_hash) end
end