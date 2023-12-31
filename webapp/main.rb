require "sinatra"
require "sinatra/reloader" if ENV['RACK_ENV'] == 'development'
require "mysql2"
require "tilt/erubis"
require "redcarpet"
require "fileutils"
require "aws-sdk-s3"
require "securerandom"
require "json"
require "sinatra/cross_origin"
require "date"
require "uri"
require "down"
require "googleauth"
require "jwt"
require "logger"

require_relative "./database/database_connection"
require_relative "incomming_status_information_data_storage"
require_relative "ai_connections"
require_relative "user"
require_relative "aws_s3_connection"

logger = Logger.new(STDOUT)
logger.level = Logger::INFO


db_connection = DatabaseConnection.new
db_connection.create_tables

active_user_list = ActiveUserList.new

access_key = ENV['AWS_IAM_USER_TEST_ACCESS_KEY']
secret_key = ENV['AWS_IAM_USER_TEST_SECRET_ACCESS_KEY']
region = ENV['AWS_S3_REGION']
bucket_name = ENV['AWS_S3_BUCKET_NAME']

aws_s3_connection = AwsS3.new(bucket_name: bucket_name, region: region, access_key: access_key, secret_key: secret_key)


configure do
  enable :cross_origin
  enable :sessions
  set :session_secret, ENV['TANDEM_SESSION_SECRET']
end

before '/protected/*' do
  redirect '/login' if session[:logged_in?] != true
end

get '/' do
  erb :home
end

get '/login' do
  @client_id = ENV['GOOGLE_CLIENT_ID']
  response.headers['Cross-Origin-Opener-Policy'] = 'same-origin-allow-popups'
  erb :login
end


get '/protected/conversation_list' do
  @user = active_user_list.load_user(session[:user_id])

  if session[:conversation_changed] == true 
    @user.conversations.each do |conversation|
      if conversation.conversation_id == session[:last_conversation]
        conversation.picture_changed = true
        conversation.name = LanguageProcessingAI.generate_response(12, Summarizer.new(@user.current_conversation.interlocutor_sections.dup)) 
      end
    end
    session[:conversation_changed] = false
  end
  @user.update_conversation_table(db_connection, session[:last_conversation]) if !session[:last_conversation].nil?
  session[:last_conversation] = nil
  
  erb :conversation_list
end

get '/protected/conversation/update_status' do
  user = active_user_list.load_user(session[:user_id])
  
  content_type :json
  user.current_conversation.client_information.to_json
end

get '/protected/conversation/create' do 
  user = active_user_list.load_user(session[:user_id])
  user.create_conversation(db_connection)
  redirect '/protected/conversation_list'
end

get '/protected/conversation/:conversation_id' do
  @user = active_user_list.load_user(session[:user_id])
  @user.enter_conversation(params['conversation_id'])
  @conversation = combine_sections(@user.current_conversation.interlocutor_sections, @user.current_conversation.corrector_sections)

  erb :conversation
end 

get '/protected/conversation/:id/delete' do
  user = active_user_list.load_user(session[:user_id])
  user.delete_conversation(params['id'], db_connection)
  redirect '/protected/conversation_list'
end

get '/protected/conversation/:id/new_picture' do
  conversation_id = params['id']
  user = active_user_list.load_user(session[:user_id])
  picture = Artist.create_image(user.current_conversation.name)
  user.current_conversation.picture = picture
  user.update_conversation_picture(db_connection, conversation_id, picture)
  user.current_conversation.picture_changed = false
  status 200
end

get '/protected/iteration_end' do
  if request.env['HTTP_ITERATION_END'] == 'true'
    user = active_user_list.load_user(session[:user_id]) 
    user.upload_conversation_to_db(db_connection)
  end
  status 201
end


get '/protected/audio_file/:audio_file' do
  send_file "./public/audio_files/#{params['audio_file']}", type: 'audio/wav'
end

get '/protected/audio_file_upload_success' do 
  user = active_user_list.load_user(session[:user_id])
  
  time_start = Time.now
  user_text = speech_recognition_transcription_ai_process(user, aws_s3_connection)
  time_end = Time.now
  logger.info("Time for speech_recog_trans_ai: #{time_end - time_start}")
  
  time_start = Time.now
  interlocutor_text = language_processing_ai_process(user, user_text)
  time_end = Time.now
  logger.info("Time for language_processing_ai: #{time_end - time_start}")

  time_start = Time.now
  voice_generator_ai_process(user, interlocutor_text, db_connection)
  time_end = Time.now
  logger.info("Time for voice_generation_ai: #{time_end - time_start}")
  
  status 201
end


get '/protected/get_upload_url_for_client' do
  user = active_user_list.load_user(session[:user_id])
  session[:conversation_changed] = true
  session[:last_conversation] = user.current_conversation_id
  user.current_conversation.reset
  

  file_name = "recording_#{db_connection.create_uuid}.wav"#"recording_#{SecureRandom.uuid}.wav" # Generate a unique filename

  
  audio_file_url = aws_s3_connection.get_presigned_url_s3(file_name, 'upload_client', :put)

  user.current_conversation.data[:speech_recognition_transcription_ai_audio_file_key] = file_name
  content_type :json
  audio_file_url.to_json
end

post '/auth-receiver' do 
  google_auth = request.params['credential']
  id_token = google_auth # Get the ID token from the POST request

  allowed_client_ids = [ENV['GOOGLE_CLIENT_ID']]

  begin
    decoded_token = JWT.decode(
      id_token, nil, false,
      algorithms: ['RS256'],
      verify_iss: true,
      iss: ['accounts.google.com', 'https://accounts.google.com'],
      verify_aud: true,
      aud: allowed_client_ids
    )

    user_info = decoded_token[0]

    user_id = active_user_list.add_user(user_info['sub'], db_connection)
    session[:user_id] = user_id
    session[:logged_in?] = true
    
    redirect '/'
  rescue JWT::DecodeError, JWT::VerificationError
    status 401
    body 'Token verification failed'
  end
  
end

post '/protected/listen_correction' do 
  text = URI.decode_www_form_component(request.body.read)[/\s{1}.*\)/][1..-2]
  file_name = "recording_#{db_connection.create_uuid}.wav"
  path = "./public/audio_files/#{file_name}"
  response = VoiceGeneratorAI.generate_response(text)

  File.open(path, 'wb') do |file|
    file.write(response)
  end
  { audioFileName: file_name }.to_json
end



def combine_sections(interlocutor_sections, corrector_sections)
  result = []
  user = interlocutor_sections.select{ |row| row[:role] == 'user' }
  interlocutor = interlocutor_sections.select{ |row| row[:role] == 'assistant' }
  corrector = corrector_sections.select{ |row| row[:role] == 'assistant' }
  user.each_with_index do |user_row, index|
    result << [[{role: user_row[:role], content: user_row[:content]},{role: corrector[index][:role], content: corrector[index][:content]}],{role: interlocutor[index][:role], content: interlocutor[index][:content]}]

  end
  result
end


def speech_recognition_transcription_ai_process(user, aws_s3_connection)
  conversation = user.current_conversation
  audio_file_key = conversation.data[:speech_recognition_transcription_ai_audio_file_key]
  audio_file_url = aws_s3_connection.get_presigned_url_s3(audio_file_key, 'upload_client', :get)[:url]
  
  timestamp_input = user.timestamp
  response = SpeechRecogTransAI.generate_response(audio_file_url)
  timestamp_output = user.timestamp
  healthcode = 200

  conversation.save_speech_recognition_transcription_ai_data(
    user.user_id, 
    output_text: response, 
    timestamp_input: timestamp_input, 
    timestamp_output: timestamp_output, 
    healthcode: healthcode
  )
  response
end

def language_processing_ai_process(user, user_text)
  conversation = user.current_conversation
  conversation.interlocutor_sections << {role: 'user', content: user_text}
  conversation.corrector_sections << {role: 'user', content: user_text}

  interlocutor_conversation = conversation.interlocutor_sections.dup #{role: 'user', content: input_text}
  corrector_conversation = conversation.corrector_sections.dup

  timestamp_input = user.timestamp
  corrector_response, interlocutor_response = LanguageProcessingAI.generate_response(100, Corrector.new(corrector_conversation), Interlocutor.new(interlocutor_conversation))
  timestamp_output = user.timestamp
  healthcode = 200
  conversation.interlocutor_sections << {role: 'assistant', content: interlocutor_response}
  conversation.corrector_sections << {role: 'assistant', content: corrector_response}
  
  conversation.save_language_processing_ai_data(
    user.user_id, 
    input_text: user_text,
    interlocutor_output_text: interlocutor_response,
    corrector_output_text: corrector_response,
    timestamp_input: timestamp_input, 
    timestamp_output: timestamp_output, 
    healthcode: healthcode
  )
  interlocutor_response
end


def voice_generator_ai_process(user, input_text, db_connection)
  file_name = "recording_#{db_connection.create_uuid}.wav"
  path = "./public/audio_files/#{file_name}"
  
  timestamp_input = user.timestamp
  response = VoiceGeneratorAI.generate_response(input_text)
  timestamp_output = user.timestamp
  

  File.open(path, 'wb') do |file|
    file.write(response)
  end
  
  user.current_conversation.save_voice_generator_ai_data(
    user.user_id,
    input_text: input_text, 
    audio_file_key: file_name,
    timestamp_input: timestamp_input,
    timestamp_output: timestamp_output,
    healthcode: 200
  )

  file_name

end











