class Nomination
  include DataMapper::Resource
  
  property :id, Serial
  property :score, Integer, :default => 0
  property :force_score, Integer, :default => 3
  property :status, String, :length => 20
  property :nominated_by, String
  property :played_at, DateTime
  property :created_at, DateTime
    
  belongs_to :album
  has n, :votes, :type => nil
  has n, :force_votes, :class_name => "Vote", :type => "force"
  
  default_scope(:default).update :status => "active", :order => [:score.desc, :created_at]
  
  def artist; album.artist end
  def name; album.name end
  
  def owned_by?(ip); nominated_by == ip end
  
  def vote(value, ip)
    return if votes.map { |v| v.ip }.include?(ip)
    
    self.votes.create(:value => value, :ip => ip) && self.score = score + value
    self.status = "deleted" if score <= -3
    save
  end
  def can_be_voted_for_by?(ip); !votes.map { |v| v.ip }.include?(ip) end
  
  def remove(ip); self.update_attributes(:status => "deleted") if owned_by?(ip) end
  
  def force(ip)
    return if force_votes.map { |v| v.ip }.include?(ip)
    
    self.force_votes.create(:value => 1, :ip => ip, :type => "force") && self.update_attributes(:force_score => force_score - 1)
    MpdProxy.play_next if force_score <= 0
  end
  def can_be_forced_by?(ip); !force_votes.map { |v| v.ip }.include?(ip) end
  
  class << self
    def current; first :status => "played", :order => [:played_at.desc] end
  end
end