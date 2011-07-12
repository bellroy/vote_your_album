class Nomination
  include DataMapper::Resource

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
  has n, :negative_votes, "Vote", :type => "vote", :value.lt => 0
  has n, :updates

  # delegation
  [:artist, :name, :art, :tags].each do |method_name|
    define_method method_name do
      album && album.send(method_name)
    end
  end

  def ttl
    expires_at && ((expires_at - DateTime.now).to_f * 86400).to_i
  end

  def owned_by?(current_user)
    user == current_user
  end

  def nominated_by
    (user && user.real_name) || "Dr Random"
  end

  def score_s
    (score > 0 ? "+" : "") + score.to_s
  end

  def score_class
    case
    when score > 0
      "positive-score"
    else
      ""
    end
  end

  # Vote methods
  # ----------------------------------------------------------------------
  def vote(value, current_user)
    return unless can_be_voted_for_by?(current_user)

    self.score = score + value

    scope = (value > 0 ? :votes : :negative_votes)
    vote = send(scope).create(:user => current_user, :value => value, :type => "vote")
    save

    MpdProxy.clear_playlist if score == 0

    Update.log "#{value > 0 ? "+1" : "-1"} for '#{artist} - #{name}' from <i>#{current_user.real_name}</i>", self, current_user
  end

  def can_be_voted_for_by?(current_user)
    !(votes + negative_votes).map { |v| v.user }.include?(current_user)
  end

  def remove(current_user)
    self.update(:status => "deleted") if owned_by?(current_user)

    Update.log "<i>#{current_user.real_name}</i> removed '#{artist} - #{name}'", self, current_user
  end

  def play(mpd)
    update :status => "played", :played_at => Time.now
    votes.create :user => user, :type => "vote", :value => 1
    songs.each { |song| mpd.add song.file }
  end

  # Class methods
  # ----------------------------------------------------------------------
  class << self
    def active
      clean
      all :status => "active", :order => [:score.desc, :created_at]
    end

    def clean
      all(:status => "active").each { |nom| nom.update(:status => "deleted") if nom.ttl && nom.ttl <= 0 }
    end

    def played
      all :status => "played", :order => [:played_at.desc]
    end

    def current
      played.first
    end
  end
end
