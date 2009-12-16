class Nomination
  include DataMapper::Resource

  DEFAULT_ELIMINATION_SCORE = -3
  TTL = 3 * 60 * 60 # 3 h

  property :id, Serial
  property :score, Integer, :default => 0
  property :status, String, :length => 20
  property :played_at, DateTime
  property :created_at, DateTime
  property :expires_at, DateTime

  belongs_to :album
  belongs_to :user
  has n, :songs, :through => Resource
  has n, :votes, :type => "vote", :value.gt => 0
  has n, :negative_votes, :model => "Vote", :type => "vote", :value.lt => 0
  has n, :down_votes, :model => "Vote", :type => "force"
  has n, :ratings, :model => "Vote", :type => "rating"

  def artist; album.artist end
  def name; album.name end
  def ttl; expires_at && ((expires_at - DateTime.now).to_f * 86400).to_i end

  def owned_by?(ip); user && user.ip == ip end

  # Song management methods
  # ----------------------------------------------------------------------
  def add(song_id, ip)
    return unless owned_by?(ip)

    song = album.songs.get(song_id)
    if song && !songs.include?(song)
      self.songs << song
      save
    end
  end
  def delete(song_id, ip)
    return unless owned_by?(ip)

    song = NominationSong.first(:nomination_id => id, :song_id => song_id)
    song.destroy if song
  end

  # Vote methods
  # ----------------------------------------------------------------------
  def vote(value, ip)
    return unless can_be_voted_for_by?(ip)

    self.score = score + value
    self.send(value > 0 ? :votes : :negative_votes).create :user => User.get_or_create_by(ip), :value => value, :type => "vote"
    self.status = "deleted" if score <= DEFAULT_ELIMINATION_SCORE

    if score < 0
      self.expires_at = (Time.now + TTL) unless ttl
    elsif ttl
      self.expires_at = nil
    end

    save
  end
  def can_be_voted_for_by?(ip); !(votes + negative_votes).map { |v| v.user }.include?(User.get_or_create_by(ip)) end

  def remove(ip); self.update(:status => "deleted") if owned_by?(ip) end

  # Force methods
  # ----------------------------------------------------------------------
  def down_votes_necessary; [score + 2, 1].max - down_votes.inject(0) { |sum, v| sum + v.value } end
  def force(ip)
    return unless can_be_forced_by?(ip)

    self.down_votes.create :user => User.get_or_create_by(ip), :value => 1, :type => "force"
    MpdProxy.execute(:clear) if down_votes_necessary <= 0
  end
  def can_be_forced_by?(ip); !down_votes.map { |v| v.user }.include?(User.get_or_create_by(ip)) end

  # Rate methods
  # ----------------------------------------------------------------------
  def rate(value, ip)
    return unless can_be_rated_by?(ip)
    self.ratings.create :user => User.get_or_create_by(ip), :value => [[value, 1].max, 5].min, :type => "rating"
  end
  def can_be_rated_by?(ip); !ratings.map { |v| v.user }.include?(User.get_or_create_by(ip)) end

  # Class methods
  # ----------------------------------------------------------------------
  class << self
    def active
      clean
      all :status => "active", :order => [:score.desc, :created_at]
    end
    def clean
      all(:status => "active", :score.lt => 0).each { |nom| nom.update(:status => "deleted") if nom.ttl && nom.ttl <= 0 }
    end

    def played; all :status => "played", :order => [:played_at.desc] end
    def current; played.first end
  end
end