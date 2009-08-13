class FileMutex
  FILE = "/tmp/vote_your_album.mutex"
  
  def synchronize(&block)
    while (counter ||= 0) < 100 && File.exists?(FILE) do
      sleep(0.1)
      counter += 1
    end 
    
    File.open FILE, "w"
    yield
    File.delete FILE
  end
end