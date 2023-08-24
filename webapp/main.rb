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
require "uri"
require "down"
require "googleauth"
require "jwt"

require_relative "./database/database_connection"
require_relative "incomming_status_information_data_storage"
require_relative "ai_connections"
require_relative "user"
require_relative "aws_s3_connection"

iteration_information_obj = IncommingStatusInformationData.new

db_connection = DatabaseConnection.new
db_connection.create_tables

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
        conversation.name = LanguageProcessingAI.summarise_text_to_title(@user.current_conversation.interlocutor_sections.dup) 
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


get '/protected/get_upload_url_for_client' do
  user = active_user_list.load_user(session[:user_id])
  session[:conversation_changed] = true
  session[:last_conversation] = user.current_conversation_id
  user.current_conversation.reset
  iteration_information_obj.create_iteration_temp_storage(user.user_id, user.current_conversation)
  
  file_name = "recording_49688ab8-9eb4-48f5-911e-e968ae5b99f4.wav"#"recording_#{SecureRandom.uuid}.wav" # Generate a unique filename
  
  url_and_filename = aws_s3_connection.get_presigned_url_s3(file_name, 'upload_client')

  iteration_information_obj.bucket[user.user_id].data[:speech_recognition_transcription_ai_audio_file_key] = file_name
  content_type :json
  url_and_filename.to_json
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
  p text = URI.decode_www_form_component(request.body.read)[/\s{1}.*\)/][1..-2]

  { audioFileName: 'recording_49688ab8-9eb4-48f5-911e-e968ae5b99f4.wav' }.to_json
end




post '/speech_recognition_transcription_ai_result' do
  output_text = request.body.read
  headers = request.env
  audio_file_key = headers['HTTP_AUDIO_FILE_KEY']

  user_id = find_user_id_by_audio_file_key(audio_file_key, iteration_information_obj)

  # post request contains [user_id, output_text, timestamp_input, timestamp_output, healthcode]
  speech_recognition_transcription_ai_output_text = speech_recognition_transcription_ai_process(iteration_information_obj, headers, output_text, user_id)
  #------------------------------------------------------#
  
  language_processing_ai_output_text = language_processing_ai_process(iteration_information_obj, speech_recognition_transcription_ai_output_text, user_id)
  
  #------------------------------------------------------#

  voice_generator_ai_audio_file = voice_generator_ai_process(iteration_information_obj, language_processing_ai_output_text, user_id)
  # store audiofile to audio_files folder
 
  aws_s3_connection.upload_audio_file(voice_generator_ai_audio_file)
  # test
  status 201
end

def find_user_id_by_audio_file_key(audio_file_key, iteration_information_obj)
  iteration_information_obj.bucket.each do |user_id, conversation|
    return user_id if conversation.data[:speech_recognition_transcription_ai_audio_file_key] == audio_file_key
  end
  'not found'
end

def speech_recognition_transcription_ai_process(iteration_information_obj, headers, output_text, user_id)
  timestamp_input = headers['HTTP_TIMESTAMP_INPUT']
  timestamp_output = headers['HTTP_TIMESTAMP_OUTPUT']
  healthcode = headers['HTTP_HEALTHCODE']


  iteration_information_obj.bucket[user_id].save_speech_recognition_transcription_ai_data(
    user_id,
    output_text: output_text, 
    timestamp_input: timestamp_input, 
    timestamp_output: timestamp_output, 
    healthcode: healthcode
  )
  output_text
end

def language_processing_ai_process(iteration_information_obj, input_text, user_id)
  
  iteration_information_obj.bucket[user_id].interlocutor_sections << {role: 'user', content: input_text}
  iteration_information_obj.bucket[user_id].corrector_sections << {role: 'user', content: input_text}

  interlocutor_conversation = iteration_information_obj.bucket[user_id].interlocutor_sections.dup #{role: 'user', content: input_text}
  corrector_conversation = iteration_information_obj.bucket[user_id].corrector_sections.dup
  
  timestamp_input = DateTime.now
  interlocutor_response = Interlocutor.generate_response(interlocutor_conversation)
  corrector_response = Corrector.generate_response(corrector_conversation)
  timestamp_output = DateTime.now
  
 
  iteration_information_obj.bucket[user_id].interlocutor_sections << {role: 'assistant', content: interlocutor_response}
  iteration_information_obj.bucket[user_id].corrector_sections << {role: 'assistant', content: corrector_response}
  
  
  iteration_information_obj.bucket[user_id].save_language_processing_ai_data(
    user_id, 
    input_text: input_text,
    interlocutor_output_text: interlocutor_response, 
    corrector_output_text: corrector_response,
    timestamp_input: timestamp_input, 
    timestamp_output: timestamp_output,
    healthcode: 200
  )

  interlocutor_response
end

def voice_generator_ai_process(iteration_information_obj, input_text, user_id)
  timestamp_input = DateTime.now
  response = 'recording_49688ab8-9eb4-48f5-911e-e968ae5b99f4.wav'#voice_generator_ai.generate_response(input_text)
  timestamp_output = DateTime.now
  
  iteration_information_obj.bucket[user_id].save_voice_generator_ai_data(
    user_id,
    input_text: input_text, 
    audio_file_key: response,
    timestamp_input: timestamp_input,
    timestamp_output: timestamp_output,
    healthcode: 200
  )
  
  response
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





