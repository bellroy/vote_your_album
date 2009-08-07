class Album
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 100
  property :name, String, :length => 100
  
  belongs_to :library
end