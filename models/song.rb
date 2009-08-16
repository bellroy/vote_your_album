class Song
  include DataMapper::Resource
  
  property :id, Serial
  property :track, String, :length => 10
  property :artist, String, :length => 100
  property :title, String, :length => 100
  property :file, String, :length => 200
  
  belongs_to :album
  
  default_scope(:default).update :order => [:track]
end