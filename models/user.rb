class User
  include DataMapper::Resource

  property :id, Serial
  property :identifier, String, :length => 100
  property :username, String, :length => 100
  property :name, String, :length => 200

  def real_name
    name || username
  end

  def self.create_from_profile(profile)
    create  :identifier => profile["identifier"],
            :username => profile["preferredUsername"],
            :name => (profile["name"] ? profile["name"]["givenName"] : profile["displayName"])
  end
end
