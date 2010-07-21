require 'httparty'

module LastFm
  def self.included(recipient)
    recipient.class_eval do
      include HTTParty
      base_uri "http://ws.audioscrobbler.com"
      default_params :api_key => "46021e7f85a446b1097cfe618f10ce3a"
    end
  end
end
