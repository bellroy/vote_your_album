class Library
  @list, @next = [], []
  
  class << self
    def list; @list.sort_by { |a| a.name } end
    def list=(list); @list = list end
    
    def next; @next.sort_by { |a| a.votes }.reverse end
    def <<(album); @next << album end
  end
end

Album = Struct.new(:id, :name, :votes)
Album.class_eval do
  def vote(with); self.votes += with end
end