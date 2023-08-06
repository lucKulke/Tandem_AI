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

OpenAI.configure do |config|
  config.access_token = 'YOUR_API_KEY'
end

CHAT_GPT_SYSTEM_MESSAGE = "You are a helpful assistant"

# This endpoint generates a pre-signed URL and includes the filename in the response
user = User.new

post '/get_upload_url' do
  s3 = Aws::S3::Resource.new
  filename = "recording_#{SecureRandom.uuid}.wav" # Generate a unique filename

  obj = s3.bucket('audio-files-tandem-ai').object("uploads/#{filename}")
  
  url = obj.presigned_url(:put, expires_in: 3600) # URL expires in 1 hour
  
  content_type :json
  { url: url, filename: filename }.to_json
end

post '/get_visper_result' do

# get visper text

# store text in user obj
text = 'How are you?'
# send text to chat gpt
response = generate_response(conversation)
# receive answer (text) from chat gpt

# store text in user obj

# send text to "text to speach AI"
end

post '/get_result_audio_file_reference' do 

  # make s3 request for presigned url for downloading audio file
  # send back to client

  # store in user obj

end


get "/" do 
  erb :home
end


def generate_response_chat_gpt(conversation)
  response = OpenAI::ChatCompletion.create(
    model: 'gpt-3.5-turbo',
    messages: [{ role: 'user', content: conversation },
               {role: 'system', content: CHAT_GPT_SYSTEM_MESSAGE}],
    temperature: 0.7
  )

  response.choices[0].message.content
end

