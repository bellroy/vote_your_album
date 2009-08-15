class Vote
  include DataMapper::Resource
  
  property :id, Serial
  property :value, Integer
  property :ip, String
  
  belongs_to :nomination
  belongs_to :played_album
end