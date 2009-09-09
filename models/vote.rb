class Vote
  include DataMapper::Resource
  
  property :id, Serial
  property :value, Integer
  property :type, String, :length => 20
  
  belongs_to :nomination
  belongs_to :user
end