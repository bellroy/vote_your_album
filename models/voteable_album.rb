class VoteableAlbum
  include DataMapper::Resource
  include BelongsToAlbum
  
  property :id, Serial
  property :created_at, Time
  property :added_by, String
  
  def to_hash(ip); { :id => id, :score => score, :voteable => can_be_voted_for_by?(ip), :added_by => added_by }.merge(album.to_hash) end
end