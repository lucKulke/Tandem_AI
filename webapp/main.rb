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

# require_relative "database_helper"
# require_relative "user"
require_relative "incomming_status_information_data_storage"
require_relative "ai_connections"
require_relative "user"
require_relative "aws_s3_connection"

iteration_information_obj = IncommingStatusInformationData.new

language_processing_ai = LanguageProcessingAI.new(api_key: ENV["CHAT_GPT_KEY"])

voice_generator_ai = VoiceGeneratorAI.new

aws_s3_connection = AwsS3.new(bucket_name: ENV["AWS_S3_BUCKET_NAME"], ENV["AWS_S3_REGION"], access_key: ENV["IAM_USER_TEST_ACCESS_KEY"], secret_key: ENV["IAM_USER_TEST_SECRET_ACCESS_KEY"])

configure do
  enable :sessions
  set :session_secret, ENV['TANDEM_SESSION_SECRET']
end

set :public_folder, File.dirname(__FILE__) + '/audio_files'

# This endpoint generates a pre-signed URL and includes the filename in the response
get "/" do 
  #redirect "/login" if session[:logged_in?] == false
  # if user not logged in redirect to login page
  # else grap user_id + conversations from Database and create User obj with those values
  erb :home
end

get "/home" do
  #redirect "/login" if session[:logged_in?] == false

end

get "/login" do
 
  erb :login
end

post '/login_data' do
  # if login successfull load create user instance
  # first_name = google_identity
  # surname = google_identity
  # email = google_identity
  if true
    session[:user] = User.new(first_name, surname, email)
    session[:logged_in?] = true
    redirect "/home"
  end
end

get "/conversations/:conversation_id" do
  

  erb :conversation
end 

get '/conversations/:conversation_id/update_status' do 
  user = session[:user]
  user.update_conversation_data(iteration_information_obj)
  
  content_type :jason
  user.current_conversation.data.to_json
end

get '/audio_files/:audio_file' do 
  send_file "audio_files/#{params['audio_file']}", type: 'audio/wav'
end

post '/get_upload_url_for_client' do
  # start iteration
  user = session[:user]
  iteration_information_obj.delete_iteration_temp_storage(user.user_id)
  iteration_information_obj.create_iteration_temp_storage(user.user_id, user.current_conversation.conversation_text)
  
  filename = "recording_#{SecureRandom.uuid}.wav" # Generate a unique filename
  
  url_and_filename = get_presigned_url_s3(filename, 'upload_client')

  iteration_information_obj.save_speech_recognition_transcription_ai_data(user.user_id, "upload_client/#{file_name}")
  content_type :json
  url_and_filename.to_json
end




post '/speech_recognition_transcription_ai_result' do
  # post request contains [user_id, output_text, timestamp_input, timestamp_output, healthcode]
  speech_recognition_transcription_ai_output_text = speech_recognition_transcription_ai_process(iteration_information_obj, params)
  #------------------------------------------------------#
  
  language_processing_ai_output_text = language_processing_ai_process(iteration_information_obj, speech_recognition_transcription_ai_output_text)
  
  #------------------------------------------------------#

  voice_generator_ai_audio_file = voice_generator_ai_process(iteration_information_obj, language_processing_ai_output_text)
  # store audiofile to audio_files folder
 

  # aws_s3_connection.upload_audio_file(voice_generator_ai_audio_file)
  
  status 201
end


def speech_recognition_transcription_ai_process(iteration_information_obj, params)
  user_id = params['user_id']
  speech_recognition_transcription_ai_output_text = body
  speech_recognition_transcription_ai_timestamp_input = params['timestamp_input']
  speech_recognition_transcription_ai_timestamp_output = params['timestamp_output']
  speech_recognition_transcription_ai_health_code = params['healthcode']


  iteration_information_obj.save_speech_recognition_transcription_ai_data(
    user_id,
    output_text: speech_recognition_transcription_ai_output_text, 
    timestamp_input: speech_recognition_transcription_ai_timestamp_input, 
    timestamp_output: speech_recognition_transcription_ai_timestamp_output, 
    healthcode: speech_recognition_transcription_ai_health_code
  )
  speech_recognition_transcription_ai_output_text
end

def language_processing_ai_process(iteration_information_obj, input_text)

  conversation = iteration_information_obj.bucket[user_id][:conversation] + input_text
  language_processing_ai_timestamp_input = DateTime.now
  language_processing_ai_response = language_processing_ai.generate_response(conversation)
  language_processing_ai_timestamp_output = DateTime.now

  language_processing_ai_healthcode = 200
  
  if language_processing_ai_response.is_a? Array
    language_processing_ai_healthcode = language_processing_ai_response[0]
    language_processing_ai_response = language_processing_ai_response[1]
  end
  
  iteration_information_obj.save_language_processing_ai_data(
    user_id, 
    input_text: speech_recognition_transcription_ai_output_text,
    output_text: language_processing_ai_response, 
    timestamp_input: language_processing_ai_timestamp_input, 
    timestamp_output: language_processing_ai_timestamp_output,
    health_code: language_processing_ai_healthcode
  )
  
end

def voice_generator_ai_process(iteration_information_obj, input_text)
  voice_generator_ai_timestamp_input = DateTime.now
  voice_generator_ai_response = 'recording_49688ab8-9eb4-48f5-911e-e968ae5b99f4.wav'#voice_generator_ai.generate_response(input_text)
  voice_generator_ai_timestamp_output = DateTime.now
  
  file_name_key = 'test'

  iteration_information_obj.save_voice_generation_ai_data(
    user_id,
    input_text: input_text, 
    audio_file_key: file_name_key,
    timestamp_input: voice_generator_ai_timestamp_input,
    timestamp_output: voice_generator_ai_timestamp_output,
    health_code: nil
  )

  iteration_information_obj.bucket[user_id][:ai_audio_file_on_server] = voice_generator_ai_response

  voice_generator_ai_response #filter audio_file_key

end








