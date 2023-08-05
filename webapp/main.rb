require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "fileutils"
require "aws-sdk-s3"
require "securerandom"
require "json"
require "sinatra/cross_origin"

configure do
  enable :sessions
  set :session_secret, ENV['TANDEM_SESSION']

end

Aws.config.update(
  region: 'eu-north-1',
  credentials: Aws::Credentials.new(ENV["IAM_USER_TEST_ACCESS_KEY"], ENV["IAM_USER_TEST_SECRET_ACCESS_KEY"])
)


# This endpoint generates a pre-signed URL and includes the filename in the response
post '/get_upload_url' do
  s3 = Aws::S3::Resource.new
  filename = "recording_#{SecureRandom.uuid}.wav" # Generate a unique filename

  obj = s3.bucket('audio-files-tandem-ai').object("uploads/#{filename}")
  
  url = obj.presigned_url(:put, expires_in: 3600) # URL expires in 1 hour
  
  content_type :json
  { url: url, filename: filename }.to_json
end

get "/" do 
  erb :home
end




