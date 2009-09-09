class User
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :length => 100
  property :ip, String, :length => 20
  
  def has_name?; name && name != "" end
  
  def self.get_or_create_by(ip); first(:ip => ip) || create(:ip => ip) end
end