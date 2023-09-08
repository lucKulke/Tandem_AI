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
require "redis"

require_relative "./database/database_connection"
require_relative "./database/redis_connection"
require_relative "ai_connections"
require_relative "user"
require_relative "aws_s3_connection"

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

DB_CONFIG = {
  host: ENV['DB_HOST'],
  port: ENV['DB_PORT'],
  username: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD'],
  database: ENV['DB_NAME']
}

db_connection = DatabaseConnection.new(db_config, logger)
db_connection.create_tables

redis_connection = RedisConnection.new(ENV['REDIS_HOST'], ENV['REDIS_PORT'], ENV['REDIS_DB'], logger)

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
  user_id = session[:user_id]
  @user = load_user(user_id, db_connection)

  if session[:conversation_changed] == true 
    conversation_id = session[:last_conversation]
    conversation = @user.select_conversation(conversation_id)
    conversation.name = LanguageProcessingAI.generate_response(12, Summarizer.new(@user.current_conversation.interlocutor_sections.dup))
    session[:picture_changeable] = true
    db_connection.update_conversation_name(conversation_id, conversation.name)
    session[:conversation_changed] = false
  end

  session[:last_conversation] = nil
  
  erb :conversation_list
end

get '/protected/conversation/update_status' do
  user_id = session[:user_id]
  
  response = IterationData.new(user_id ,redis_connection)
  
  content_type :json
  response.create.to_json
end

get '/protected/conversation/create' do 
  user_id = session[:user_id]
  user = load_user(user_id, db_connection)
  user.create_conversation(db_connection)
  redirect '/protected/conversation_list'
end

get '/protected/conversation/:conversation_id' do
  user_id = session[:user_id]
  @user = load_user(user_id, db_connection)
  @user.enter_conversation(params['conversation_id'])
  conversation = @user.select_current_conversation
  @conversation = combine_sections(conversation.interlocutor_sections, conversation.corrector_sections)

  redis_connection.create_cache(user_id, conversation.interlocutor_sections, conversation.corrector_sections, conversation.conversation_id)

  erb :conversation
end 

get '/protected/conversation/:id/delete' do
  user_id = session[:user_id]
  user = load_user(user_id, db_connection)
  conversation_id = params['id']
  user.delete_conversation(conversation_id, db_connection)
  redirect '/protected/conversation_list'
end

get '/protected/conversation/:id/new_picture' do
  conversation_id = params['id']
  user_id = session[:user_id]

  picture = Artist.create_image(user.current_conversation.name)

  session[:picture_changeable] = false
  db_connection.update_conversation_picture(conversation_id, picture)

  status 200
end

get '/protected/iteration_end' do
  user_id = session[:user_id]
  if request.env['HTTP_ITERATION_END'] == 'true'
    iteration_id = db_connection.create_uuid
    conversation_id = redis_connection.get("conversation_id_#{user_id}")
    db_connection.update_iteration_data(user_id, conversation_id , iteration_id, IterationData.new(user_id, redis_connection))
  end
  status 201
end


get '/protected/audio_file/:audio_file' do
  send_file "./public/audio_files/#{params['audio_file']}", type: 'audio/wav'
end

get '/protected/audio_file_upload_success' do 
  user_id = session[:user_id]
  time_start = Time.now
  user_text = speech_recognition_transcription_ai_process(user_id, aws_s3_connection, redis_connection)
  time_end = Time.now
  logger.info("Time for speech_recog_trans_ai: #{time_end - time_start}")
  
  time_start = Time.now
  interlocutor_text = language_processing_ai_process(user_id, user_text, redis_connection)
  time_end = Time.now
  logger.info("Time for language_processing_ai: #{time_end - time_start}")

  time_start = Time.now
  voice_generator_ai_process(user_id, interlocutor_text, db_connection, redis_connection)
  time_end = Time.now
  logger.info("Time for voice_generation_ai: #{time_end - time_start}")
  
  status 201
end


get '/protected/get_upload_url_for_client' do
  user_id = session[:user_id]
  user = load_user(user_id, db_connection)
  session[:conversation_changed] = true
  session[:last_conversation] = user.current_conversation_id
  user.current_conversation.reset
  

  file_name = "recording_#{db_connection.create_uuid}.wav"#"recording_#{SecureRandom.uuid}.wav" # Generate a unique filename

  
  audio_file_url = aws_s3_connection.get_presigned_url_s3(file_name, 'upload_client', :put)

  redis_connection.set("speech_recognition_transcription_ai_audio_file_key_#{user_id}", file_name)
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

    auth = decoded_token[0]['sub']

    user_id = db_connection.search_user_id(auth)
    if user_id.nil?
      user_id = db_connection.create_uuid
      db_connection.create_user(auth, user_id)
    end
    
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


def speech_recognition_transcription_ai_process(user_id, aws_s3_connection, cache)

  audio_file_key = cache.get("speech_recognition_transcription_ai_audio_file_key_#{user_id}")
  audio_file_url = aws_s3_connection.get_presigned_url_s3(audio_file_key, 'upload_client', :get)[:url]
  
  response = SpeechRecogTransAI.generate_response(audio_file_url)

  cache.set("speech_recognition_transcription_ai_output_text_#{user_id}", response)
  
  response
end

def language_processing_ai_process(user_id, user_text, cache)
  
  interlocutor_conversation = JSON.parse(cache.get("interlocutor_sections_#{user_id}")) #{role: 'user', content: input_text}
  corrector_conversation = JSON.parse(cache.get("corrector_sections_#{user_id}"))


  corrector_response, interlocutor_response = LanguageProcessingAI.generate_response(100, Corrector.new(corrector_conversation), Interlocutor.new(interlocutor_conversation))
  

  interlocutor_conversation << {'role' => 'assistant', 'content' => interlocutor_response}
  corrector_conversation << {'role' => 'assistant', 'content' => corrector_response}
  
  cache.set("language_processing_ai_interlocutor_output_text_#{user_id}", interlocutor_response)
  cache.set("language_processing_ai_corrector_output_text_#{user_id}", corrector_response)
  cache.update_sections(user_id, interlocutor_conversation, corrector_conversation)
  
  
  interlocutor_response
end


def voice_generator_ai_process(user, input_text, db_connection, cache)
  file_name = "recording_#{db_connection.create_uuid}.wav"
  path = "./public/audio_files/#{file_name}"
  
 
  response = VoiceGeneratorAI.generate_response(input_text)

  
  File.open(path, 'wb') do |file|
    file.write(response)
  end
  
  cache.set("voice_generator_ai_audio_file_key_#{user_id}", file_name)

  file_name

end

def load_user(user_id, db_connection)
  User.new(user_id, db_connection)
end










