class VoteableAlbum
  include DataMapper::Resource
  
  property :id, Serial
  property :artist, String, :length => 100
  property :name, String, :length => 100
  
  belongs_to :library
  has n, :votes
    
  def rating; votes.map { |v| v.value }.inject(0) { |sum, v| sum + v } end  
  def vote(value, ip)
    return if votes.map { |v| v.ip }.include?(ip)
    self.votes.create :value => value, :ip => ip
  end
  
  def can_be_voted_for_by?(ip); !votes.map { |v| v.ip }.include?(ip) end
  def to_hash(ip); { :id => id, :artist => artist, :name => name, :rating => rating, :votable => can_be_voted_for_by?(ip) } end
end