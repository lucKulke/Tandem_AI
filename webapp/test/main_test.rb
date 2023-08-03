ENV["RACK_ENV"] = "test"
require_relative "../main.rb"

require "minitest/autorun"
require "rack/test"
require "fileutils"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end