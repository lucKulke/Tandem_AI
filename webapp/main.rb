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

db_connection = DatabaseConnection.new.create_tables

active_user_list = ActiveUserList.new

access_key = ENV['AWS_IAM_USER_TEST_ACCESS_KEY']
secret_key = ENV['AWS_IAM_USER_TEST_SECRET_ACCESS_KEY']
region = ENV['AWS_S3_REGION']
bucket_name = ENV['AWS_S3_BUCKET_NAME']

aws_s3_connection = AwsS3.new(bucket_name: bucket_name, region: region, access_key: access_key, secret_key: secret_key)


configure do
  enable :sessions
  set :session_secret, ENV['TANDEM_SESSION_SECRET']
end



get "/" do
  if session[:logged_in?].nil?
    user_id = active_user_list.add_user('Max', 'Mustermann', 'example@gmail.com', db_connection)
    session[:user_id] = user_id
    session[:logged_in?] = true
  end

  session[:changed_data] = false

  erb :home
end

get "/conversation_list" do
  @user = active_user_list.load_user(session[:user_id])
  if session[:changed_data] == true 
    @user.conversations.each do |conversation|
      if conversation.conversation_text != "conversation start: "
        conversation.name = language_processing_ai.summarise_text_to_title(conversation.conversation_text)
      end
    end
  end

  
  if !iteration_information_obj.bucket[@user.user_id].nil?
    iteration_information_obj.delete_iteration_temp_storage(@user.user_id)
  end
  erb :conversation_list
end

get "/conversation/update_status" do 
  user = active_user_list.load_user(session[:user_id])
  user.update_conversation_data(iteration_information_obj)
  
  content_type :json
  user.current_conversation.client_information.to_json
end

get "/conversation/:conversation_id" do
  session[:changed_data] = false
  @user = active_user_list.load_user(session[:user_id])
  @user.enter_conversation(params['conversation_id'])
  @conversation = format_conversation(@user.current_conversation.conversation_text)

  erb :conversation
end 

get "/iteration_end" do
  if request.env['HTTP_ITERATION_END'] == 'true'
    user = active_user_list.load_user(session[:user_id]) 
    user.upload_conversation_to_db(user.current_conversation_id, db_connection)
  end
  status 201
end


get '/audio_file/:audio_file' do
  # user = active_user_list.load_user(session[:user_id]) 
  # user.upload_conversation_to_db(user.current_conversation_id, db_connection)
  send_file "./public/audio_files/#{params['audio_file']}", type: 'audio/wav'
end





get "/get_upload_url_for_client" do
  session[:changed_data] = true
  user = active_user_list.load_user(session[:user_id])
  user.current_conversation.reset
  iteration_information_obj.delete_iteration_temp_storage(user.user_id)
  iteration_information_obj.create_iteration_temp_storage(user.user_id, user.current_conversation.conversation_text)
  
  file_name = "recording_49688ab8-9eb4-48f5-911e-e968ae5b99f4.wav"#"recording_#{SecureRandom.uuid}.wav" # Generate a unique filename
  
  url_and_filename = aws_s3_connection.get_presigned_url_s3(file_name, 'upload_client')

  iteration_information_obj.bucket[user.user_id][:speech_recognition_transcription_ai_audio_file_key] = file_name
  content_type :json
  url_and_filename.to_json
end

post "/conversation/create" do 
  user = active_user_list.load_user(session[:user_id])
  user.create_conversation(db_connection)
  redirect '/conversation_list'
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
 
  aws_s3_connection.upload_audio_file(voice_generator_ai_audio_file)
  
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

  input_text_with_context = iteration_information_obj.bucket[user_id][:conversation_text] += " User: #{input_text} "

  conversation = [
    {role: "system", content: "You are a helpful assistant"},
    {role: "user", content: input_text_with_context}
  ]

  timestamp_input = DateTime.now
  response = language_processing_ai.generate_response(conversation)
  timestamp_output = DateTime.now
  response
  healthcode = 200
  
  if response.is_a? Array
    healthcode = response[0]
    response = response[1]
  else
    iteration_information_obj.bucket[user_id][:conversation_text] += (' ' + response)

  end
  
  iteration_information_obj.save_language_processing_ai_data(
    user_id, 
    input_text: input_text,
    output_text: response, 
    timestamp_input: timestamp_input, 
    timestamp_output: timestamp_output,
    healthcode: healthcode
  )

  response
  
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
    healthcode: 200
  )


  response #filter audio_file_key

end

def format_conversation(conversation)
  formated_version = conversation[0..19] + "<br>"
  conversation[20..-1].split(' ').each do |word|
    if word == 'User:' 
      formated_version += ("<br><br>" + word)
    elsif word == 'Assistant:' || word == 'Assistent:'
      formated_version += ("<br><br>" + word)
    else
      formated_version += (' ' + word)
    end
  end
  formated_version
end








