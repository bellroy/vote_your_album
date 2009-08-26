class Nomination
  include DataMapper::Resource
  
  DEFAULT_ELIMINATION_SCORE = -3
  DEFAULT_FORCE_SCORE = 3
  
  property :id, Serial
  property :score, Integer, :default => 0
  property :status, String, :length => 20
  property :nominated_by, String
  property :played_at, DateTime
  property :created_at, DateTime
    
  belongs_to :album
  has n, :votes, :type => "vote", :value.gt => 0
  has n, :negative_votes, :class_name => "Vote", :type => "vote", :value.lt => 0
  has n, :down_votes, :class_name => "Vote", :type => "force"
  has n, :ratings, :class_name => "Vote", :type => "rating"
  
  def artist; album.artist end
  def name; album.name end
  
  def owned_by?(ip); nominated_by == ip end
  
  # Vote methods
  # ----------------------------------------------------------------------
  def vote(value, ip)
    return unless can_be_voted_for_by?(ip)
    
    self.score = score + value
    self.send(value > 0 ? :votes : :negative_votes).create :value => value, :ip => ip, :type => "vote"
    self.status = "deleted" if score <= DEFAULT_ELIMINATION_SCORE
    save
  end
  def can_be_voted_for_by?(ip); !(votes + negative_votes).map { |v| v.ip }.include?(ip) end
  
  def remove(ip); self.update_attributes(:status => "deleted") if owned_by?(ip) end

  # Force methods
  # ----------------------------------------------------------------------
  def down_votes_necessary(default = DEFAULT_FORCE_SCORE); default - down_votes.inject(0) { |sum, v| sum + v.value } end
  def force(ip)
    return unless can_be_forced_by?(ip)
    
    self.down_votes.create :value => 1, :ip => ip, :type => "force"
    MpdProxy.execute(:clear) if down_votes_necessary <= 0
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