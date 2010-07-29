class Tag
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :length => 255

  has n, :albums, :through => Resource

  def self.find_or_create_by_name(tag)
    first(:name => tag) || create(:name => tag)
  end
end
