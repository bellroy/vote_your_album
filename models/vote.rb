class Vote
  include DataMapper::Resource
  
  property :id, Serial
  property :value, Integer
  property :ip, String
  
  belongs_to :voteable_album
end