class Vote
  include DataMapper::Resource
  
  property :id, Serial
  property :value, Integer
  property :ip, String
  property :type, String, :length => 20
  
  belongs_to :nomination
end