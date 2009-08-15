class Album
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 100
  property :name, String, :length => 100
  property :last_played_at, Time
  
  belongs_to :library
  has n, :nominations
  
  def to_hash; { :artist => (artist || ""), :name => name } end
  def id_hash; to_hash.merge :id => id end
end