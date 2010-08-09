class Library

  class << self
    def update
      thread = Thread.new do
        MpdProxy.execute :update
        sleep(1) while updating?
        Album.update
      end
      thread.join
    end

    def updating?
      !!MpdProxy.execute(:status)["updating_db"]
    end
  end
end
