module BelongsToAlbum
  def self.included(recipient)
    recipient.class_eval do
      belongs_to :album
      belongs_to :library
      has n, :votes

      def artist; album.artist end
      def name; album.name end
      
      def score; votes.map { |v| v.value }.inject(0) { |sum, v| sum + v } end  
      def vote(value, ip, eliminate = false)
        return if votes.map { |v| v.ip }.include?(ip)
        self.votes.create(:value => value, :ip => ip) && votes.reload
        self.destroy if eliminate && score <= ELIMINATION_SCORE
      end

      def can_be_voted_for_by?(ip); !votes.map { |v| v.ip }.include?(ip) end
    end
  end
end