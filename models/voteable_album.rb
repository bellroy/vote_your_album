class VoteableAlbum
  include DataMapper::Resource
  
  property :id, Serial
  property :created_at, Time
  
  belongs_to :album
  belongs_to :library
  has n, :votes
  
  def artist; album.artist end
  def name; album.name end
  
  def rating; votes.map { |v| v.value }.inject(0) { |sum, v| sum + v } end  
  def vote(value, ip)
    return if votes.map { |v| v.ip }.include?(ip)
    self.votes.create :value => value, :ip => ip
  end
  
  def can_be_voted_for_by?(ip); !votes.map { |v| v.ip }.include?(ip) end
  def to_hash(ip); { :id => id, :rating => rating, :votable => can_be_voted_for_by?(ip) }.merge(album.to_hash) end
end