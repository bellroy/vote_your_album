class Nomination
  include DataMapper::Resource
  include BelongsToAlbum
  
  property :id, Serial
  property :created_at, Time
  property :nominated_by, String
  
  def to_hash(ip); { :id => id, :score => score, :voteable => can_be_voted_for_by?(ip), :nominated_by => nominated_by }.merge(album.to_hash) end
end