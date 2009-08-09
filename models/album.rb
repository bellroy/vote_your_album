class Album
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 100
  property :name, String, :length => 100
  
  belongs_to :library
  
  def to_hash; { :artist => (artist || ""), :name => name } end
end