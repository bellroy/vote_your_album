class Nomination
  include DataMapper::Resource
  
  property :id, Serial
  property :score, Integer, :default => 0
  property :status, String, :length => 20
  property :created_at, Time
  property :nominated_by, String
  
  belongs_to :album
  has n, :votes
  
  default_scope(:default).update :status => "active", :order => [:score.desc, :created_at]
  
  def artist; album.artist end
  def name; album.name end
  
  def vote(value, ip)
    return if votes.map { |v| v.ip }.include?(ip)
    
    self.votes.create(:value => value, :ip => ip) && self.score = score + value
    self.status = "deleted" if score <= ELIMINATION_SCORE
    save
  end
  def can_be_voted_for_by?(ip); !votes.map { |v| v.ip }.include?(ip) end
end