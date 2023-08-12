require "sinatra"
require "sinatra/reloader"
require "mysql2"
require "tilt/erubis"
require "redcarpet"
require "fileutils"
require "aws-sdk-s3"
require "securerandom"
require "json"
require "sinatra/cross_origin"
require "openai"
require "date"

require_relative "./database/database_connection"
require_relative "incomming_status_information_data_storage"
require_relative "ai_connections"
require_relative "user"
require_relative "aws_s3_connection"

iteration_information_obj = IncommingStatusInformationData.new

language_processing_ai = LanguageProcessingAI.new

voice_generator_ai = VoiceGeneratorAI.new

db_connection = DatabaseConnection.new.establish




def generate_s3_response(file_name, folder)
  access_key = ENV['AWS_IAM_USER_TEST_ACCESS_KEY']
  secret_key = ENV['AWS_IAM_USER_TEST_SECRET_ACCESS_KEY']
  region = ENV['AWS_S3_REGION']
  bucket_name = ENV['AWS_S3_BUCKET_NAME']
  
  Aws.config.update(
    region: region,
    credentials: Aws::Credentials.new(access_key, secret_key)
  )
  s3 = Aws::S3::Resource.new
   # Generate a unique filename

  obj = s3.bucket(bucket_name).object("#{folder}/#{file_name}")
  
  url = obj.presigned_url(:put, expires_in: 3600) # URL expires in 1 hour
  
  { url: url , file_name: file_name}
end

configure do
  enable :sessions
  set :session_secret, ENV['TANDEM_SESSION_SECRET']
end



# This endpoint generates a pre-signed URL and includes the filename in the response
get "/" do 
  if session[:user].nil?
    session[:user] = User.new('Max', 'Mustermann', 'example@gmail.com', db_connection)
  end
  erb :home
end

get "/conversation_list" do 
  iteration_information_obj.delete_iteration_temp_storage(session[:user].user_id)
  erb :conversation_list
end

get "/conversation/update_status" do 
  user = session[:user]
  user.update_conversation_data(iteration_information_obj)
  
  content_type :json
  user.current_conversation.client_information.to_json
end

get "/conversation/:conversation_id" do
  user = session[:user]
  user.enter_conversation(params['conversation_id'])

  erb :conversation
end 


get '/audio_files/:audio_file' do 
  
  send_file "audio_files/#{params['audio_file']}", type: 'audio/wav'
end



get "/get_upload_url_for_client" do
  # start iteration
  user = session[:user]
  user.current_conversation.reset
  iteration_information_obj.delete_iteration_temp_storage(user.user_id)
  iteration_information_obj.create_iteration_temp_storage(user.user_id, user.current_conversation.conversation_text)
  
  file_name = "recording_49688ab8-9eb4-48f5-911e-e968ae5b99f4.wav"#"recording_#{SecureRandom.uuid}.wav" # Generate a unique filename
  
  url_and_filename = generate_s3_response(file_name, 'uploads')

  iteration_information_obj.bucket[user.user_id][:speech_recognition_transcription_ai_audio_file_key] = file_name
  content_type :json
  url_and_filename.to_json
end

post "/conversation/create" do 
  session[:user].create_conversation(db_connection)
end



post '/speech_recognition_transcription_ai_result' do
  output_text = request.body.read
  headers = request.env
  audio_file_key = headers['HTTP_AUDIO_FILE_KEY']

  user_id = find_user_by_audio_file_key(audio_file_key, iteration_information_obj)

  # post request contains [user_id, output_text, timestamp_input, timestamp_output, healthcode]
  speech_recognition_transcription_ai_output_text = speech_recognition_transcription_ai_process(iteration_information_obj, headers, output_text, user_id)
  #------------------------------------------------------#
  
  language_processing_ai_output_text = language_processing_ai_process(iteration_information_obj, speech_recognition_transcription_ai_output_text, user_id, language_processing_ai)
  
  #------------------------------------------------------#

  voice_generator_ai_audio_file = voice_generator_ai_process(iteration_information_obj, language_processing_ai_output_text, user_id)
  # store audiofile to audio_files folder
 

  # aws_s3_connection.upload_audio_file(voice_generator_ai_audio_file)
  
  status 201
end

def find_user_by_audio_file_key(audio_file_key, iteration_information_obj)
  user_id = nil
  iteration_information_obj.bucket.each do |user, data|
    if data[:speech_recognition_transcription_ai_audio_file_key] == audio_file_key
      user_id = user
      break
    end
  end
  user_id

end

def speech_recognition_transcription_ai_process(iteration_information_obj, headers, output_text, user_id)
  timestamp_input = headers['HTTP_TIMESTAMP_INPUT']
  timestamp_output = headers['HTTP_TIMESTAMP_OUTPUT']
  healthcode = headers['HTTP_HEALTHCODE']


  iteration_information_obj.save_speech_recognition_transcription_ai_data(
    user_id,
    output_text: output_text, 
    timestamp_input: timestamp_input, 
    timestamp_output: timestamp_output, 
    healthcode: healthcode
  )
  output_text
end

def language_processing_ai_process(iteration_information_obj, input_text, user_id, language_processing_ai)

  #conversation = iteration_information_obj.bucket[user_id][:conversation] + input_text

  conversation = [
    {role: "system", content: "You are a helpful assistant"},
    {role: "user", content: input_text}
  ]

  timestamp_input = DateTime.now
  response = language_processing_ai.generate_response(conversation)
  timestamp_output = DateTime.now

  healthcode = 200
  
  if response.is_a? Array
    healthcode = response[0]
    response = response[1]
  end
  
  iteration_information_obj.save_language_processing_ai_data(
    user_id, 
    input_text: input_text,
    output_text: response, 
    timestamp_input: timestamp_input, 
    timestamp_output: timestamp_output,
    healthcode: healthcode
  )
  
end

def voice_generator_ai_process(iteration_information_obj, input_text, user_id)
  timestamp_input = DateTime.now
  response = 'recording_49688ab8-9eb4-48f5-911e-e968ae5b99f4.wav'#voice_generator_ai.generate_response(input_text)
  timestamp_output = DateTime.now
  

  iteration_information_obj.save_voice_generation_ai_data(
    user_id,
    input_text: input_text, 
    audio_file_key: response,
    timestamp_input: timestamp_input,
    timestamp_output: timestamp_output,
    healthcode: nil
  )


  response #filter audio_file_key

end








