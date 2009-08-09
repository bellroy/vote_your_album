require File.expand_path(File.dirname(__FILE__) + '/../vote_your_album')
require 'spec'
require 'spec/interop/test'
require 'rack/test'

set :environment, :test
include Rack::Test::Methods

require File.expand_path(File.dirname(__FILE__) + '/belongs_to_album_examples')

# Make an instance of the Sinatra app available to the specs
def app; Sinatra::Application end

DataMapper.setup(:default, "mysql://localhost/vote_your_album_test")
DataMapper.auto_migrate!