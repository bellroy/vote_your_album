class VoteableAlbum
  include DataMapper::Resource
  include BelongsToAlbum
  
  property :id, Serial
  property :created_at, Time
  
  def to_hash(ip); { :id => id, :rating => rating, :voteable => can_be_voted_for_by?(ip) }.merge(album.to_hash) end
end