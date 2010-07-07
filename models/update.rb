class Update
  include DataMapper::Resource

  property :id, Serial
  property :action, String, :length => 255
  property :time, DateTime

  default_scope(:default).update :order => [:time.desc, :id.desc], :limit => 20

  def self.log(action)
    create :action => action, :time => Time.now
  end
end
