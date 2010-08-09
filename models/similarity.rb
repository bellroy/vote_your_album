class Similarity
  include DataMapper::Resource

  # This should be unecessaruy, but it doesn't work on pepper!
  property :source_id, Integer, :key => true
  property :target_id, Integer, :key => true

  belongs_to :source, "Album"
  belongs_to :target, "Album"
end
