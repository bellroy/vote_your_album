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

    def album_paths
      leaf_paths_of MpdProxy.execute(:directories)
    end

    def leaf_paths_of(paths)
      paths.dup.reject do |path|
        paths.any? { |p| p =~ %r{^#{Regexp.escape(path)}/} }
      end
    end
  end
end
