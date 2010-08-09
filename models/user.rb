class User
  include DataMapper::Resource

  property :id, Serial
  property :identifier, String, :length => 100
  property :username, String, :length => 100
  property :name, String, :length => 200

  has n, :nominations
  has n, :played_nominations, "Nomination", :status => "played"
  has n, :votes, :type => "vote", :value.gt => 0
  has n, :negative_votes, "Vote", :type => "vote", :value.lt => 0
  has n, :down_votes, "Vote", :type => "force"
  has n, :updates

  def real_name
    name || username
  end

  def self.create_from_profile(profile)
    create  :identifier => profile["identifier"],
            :username => profile["preferredUsername"],
            :name => (profile["name"] ? profile["name"]["givenName"] : profile["displayName"])
  end
end
