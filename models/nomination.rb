class Nomination
  include DataMapper::Resource
  
  ELIMINATION_SCORE = -3
  INITIAL_FORCE_SCORE = 3
  
  property :id, Serial
  property :score, Integer, :default => 0
  property :down_votes_left, Integer, :default => INITIAL_FORCE_SCORE
  property :status, String, :length => 20
  property :nominated_by, String
  property :played_at, DateTime
  property :created_at, DateTime
    
  belongs_to :album
  has n, :votes, :type => "vote"
  has n, :down_votes, :class_name => "Vote", :type => "force"
  has n, :ratings, :class_name => "Vote", :type => "rating"
  
  def artist; album.artist end
  def name; album.name end
  
  def owned_by?(ip); nominated_by == ip end
  
  # Vote methods
  # ----------------------------------------------------------------------
  def vote(value, ip)
    return if votes.map { |v| v.ip }.include?(ip)
    
    self.votes.create(:value => value, :ip => ip, :type => "vote") && self.score = score + value
    self.status = "deleted" if score <= ELIMINATION_SCORE
    save
  end
  def can_be_voted_for_by?(ip); !votes.map { |v| v.ip }.include?(ip) end
  
  def remove(ip); self.update_attributes(:status => "deleted") if owned_by?(ip) end

  # Force methods
  # ----------------------------------------------------------------------
  def force(ip)
    return if down_votes.map { |v| v.ip }.include?(ip)
    
    self.down_votes.create(:value => 1, :ip => ip, :type => "force") && self.update_attributes(:down_votes_left => down_votes_left - 1)
    MpdProxy.play_next if down_votes_left <= 0
  end
  def can_be_forced_by?(ip); !down_votes.map { |v| v.ip }.include?(ip) end

  # Rate methods
  # ----------------------------------------------------------------------
  def rate(value, ip)
    return if ratings.map { |v| v.ip }.include?(ip)
    self.ratings.create :value => [[value, 1].max, 5].min, :ip => ip, :type => "rating"
  end
  def can_be_rated_by?(ip); !ratings.map { |v| v.ip }.include?(ip) end
  
  # Class methods
  # ----------------------------------------------------------------------
  class << self
    def active; all :status => "active", :order => [:score.desc, :created_at] end
    def played; all :status => "played", :order => [:played_at.desc] end
    def current; played.first end
  end
end