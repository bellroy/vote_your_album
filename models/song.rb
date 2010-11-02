class Song
  include DataMapper::Resource

  property :id, Serial
  property :track, Integer
  property :artist, String, :length => 200
  property :title, String, :length => 200
  property :length, Integer
  property :file, String, :length => 500

  belongs_to :album
  has n, :nominations, :through => Resource

  default_scope(:default).update :order => [:track]

  def to_hash
    {
      :id => id,
      :track => track,
      :artist => artist,
      :title => title,
      :length => length,
    }
  end
end
