class Similarity
  include DataMapper::Resource

  belongs_to :source, "Album", :key => true
  belongs_to :target, "Album", :key => true
end
