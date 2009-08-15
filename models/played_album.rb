class PlayedAlbum
  include DataMapper::Resource
  include BelongsToAlbum
  
  property :id, Serial
  
  default_scope(:default).update(:order => [:id.desc])
  
  def remaining; FORCE_VOTES - score end
  def to_hash(ip); { :remaining => remaining, :voteable => can_be_voted_for_by?(ip) }.merge(album.to_hash) end
end