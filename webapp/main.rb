require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "fileutils"

configure do
  enable :sessions
  set :session_secret, "2bcf8dda83c1f40974aacef7981dd719693da219bea74cedcfac5ba3b391a843"
end