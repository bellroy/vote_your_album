class PlayedAlbum
  include DataMapper::Resource
  include BelongsToAlbum
  
  property :id, Serial
  NECESSARY_VOTES = 3
  
  default_scope(:default).update(:order => [:id.desc])
  
  def remaining; NECESSARY_VOTES - rating end
  def to_hash(ip); { :remaining => remaining, :voteable => can_be_voted_for_by?(ip) }.merge(album.to_hash) end
end