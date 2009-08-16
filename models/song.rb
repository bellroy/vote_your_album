class Song
  include DataMapper::Resource
  
  property :id, Serial
  property :track, Integer
  property :artist, String, :length => 200
  property :title, String, :length => 200
  property :file, String, :length => 500
  
  belongs_to :album
  
  default_scope(:default).update :order => [:track]
end