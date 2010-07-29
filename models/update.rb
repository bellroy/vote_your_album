class Update
  include DataMapper::Resource

  property :id, Serial
  property :action, String, :length => 255
  property :time, DateTime

  belongs_to :user, :required => false
  belongs_to :nomination

  default_scope(:default).update :order => [:time.desc, :id.desc], :limit => 20

  def time_ago
    distance = ((DateTime.now - time) * 24 * 60).to_f.round

    case distance
      when 0               then "less than a minute ago"
      when 1               then "1 minute ago"
      when 2..44           then "#{distance} minutes ago"
      when 45..89          then "1 hour ago"
      when 90..1439        then "#{(distance.to_f / 60.0).round} hours ago"
      when 1440..2529      then "1 day ago"
      when 2530..43199     then "#{(distance.to_f / 1440.0).round} days ago"
      when 43200..86399    then "1 month ago"
      else                      "a long time ago"
    end
  end

  def self.log(action, nomination, user = nil)
    create :action => action, :time => Time.now, :user => user, :nomination => nomination
  end
end
