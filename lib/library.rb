class Library
  @list, @next = [], []
  
  class << self
    def list; @list.sort_by { |a| a.name } end
    def list=(list); @list = list end
    
    def next; @next end
    def <<(album); @next << album end
  end
end