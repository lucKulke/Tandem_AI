require_relative 'conversation'
require_relative './database/database_connection'
require 'date'

class User
  attr_accessor :current_conversation, :current_conversation_id, :conversations
  attr_reader :user_id

  def initialize(google_auth, db_connection)
    @user_id = load_user_data(google_auth, db_connection)
    @current_conversation_id = nil
    @current_conversation = nil
  end

  def timestamp
    DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
  end

  def create_conversation(db_connection)
    name = 'new Conversation'
    uuid = db_connection.create_uuid
    start_text = 'conversation start: '
    default_picture = '/images/robo.png'
    db_connection.create_conversation(self.user_id, uuid, name, default_picture, start_text, self.timestamp, 200)
    self.conversations << Conversation.new(uuid, [], [], name, 'User:', 'AI:', default_picture)
  end

  def delete_conversation(conversation_id, db_connection)
    conversations.delete_if{|conversation| conversation.conversation_id == conversation_id}
    db_connection.delete_conversation(conversation_id, 404, self.timestamp)
    current_conversation_id = nil
    current_conversation = nil
  end

  def enter_conversation(conversation_id)
    conversation = conversations.select do |conversation|
      conversation.conversation_id == conversation_id
    end
    
    self.current_conversation_id = conversation_id
    self.current_conversation = conversation.first
    self.current_conversation.reset
  end

  def load_user_data(google_auth, db_connection)
    user_id = search_user_id(google_auth, db_connection)
    if user_id.empty?
      user_id = create_user_in_db(google_auth, db_connection)
      @conversations = []
    else
      @conversations = load_conversations(user_id, db_connection)
    end
    user_id
  end

  def load_conversations(user_id, db_connection)
    return_format = []
    result = db_connection.select_conversation_id_and_name_and_picture(user_id, 200)
    result.each do |row|
      interlocutor_sections = db_connection.load_interlocutor_sections(row['conversation_id'])
      corrector_sections = db_connection.load_corrector_sections(row['conversation_id'])
      return_format << Conversation.new(row['conversation_id'], interlocutor_sections, corrector_sections, row['conversation_name'], 'User:', 'AI:', row['conversation_picture'])
    end
    return_format
  end

  def create_user_in_db(google_auth, db_connection)
    uuid = db_connection.create_uuid
    db_connection.create_user(google_auth, uuid)
    uuid # returns user_id
  end

  def search_user_id(google_auth, db_connection)
    db_connection.search_user_id(google_auth)
  end

  def update_conversation_table(db_connection, conversation_id)
    interlocutor_text = convert_to_text(current_conversation.interlocutor_sections)
    corrector_text = convert_to_text(current_conversation.corrector_sections)
    db_connection.update_conversation_table(conversation_id, current_conversation.name, current_conversation.picture, interlocutor_text, corrector_text)
  end

  def update_conversation_picture(db_connection, conversation_id, conversation_picture)
    db_connection.update_conversation_picture(conversation_id, conversation_picture)
  end

  def convert_to_text(conversation)
    text = 'conversation start: '
    conversation.each do |row|
      text += "#{row[:role]}: #{row[:content]} "
    end
    text
  end

 
  def upload_conversation_to_db(db_connection)
    iteration_id = db_connection.create_uuid
    conversation_id = self.current_conversation_id
    data = self.current_conversation.data
    audio_file_key = data[:speech_recognition_transcription_ai_audio_file_key]
    output_text = data[:speech_recognition_transcription_ai_output_text]
    timestamp_input = data[:speech_recognition_transcription_ai_timestamp_input]
    timestamp_output = data[:speech_recognition_transcription_ai_timestamp_output]
    healthcode = data[:speech_recognition_transcription_ai_healthcode]
    db_connection.upload_speech_recognition_transcription_ai_data(self.user_id, iteration_id, conversation_id, audio_file_key, output_text, timestamp_input, timestamp_output, healthcode)
      
    input_text = data[:language_processing_ai_input_text]
    interlocutor_output_text = data[:language_processing_ai_interlocutor_output_text]
    corrector_output_text = data[:language_processing_ai_corrector_output_text]
    timestamp_input = data[:language_processing_ai_timestamp_input]
    timestamp_output = data[:language_processing_ai_timestamp_output]
    healthcode = data[:language_processing_ai_healthcode]
    db_connection.upload_language_processing_ai_data(self.user_id, iteration_id, conversation_id, input_text, interlocutor_output_text, corrector_output_text, timestamp_input, timestamp_output, healthcode)

    input_text = data[:voice_generator_ai_input_text]
    audio_file_key = data[:voice_generator_ai_audio_file_key]
    timestamp_input = data[:voice_generator_ai_timestamp_input]
    timestamp_output = data[:voice_generator_ai_timestamp_output]
    healthcode = data[:voice_generator_ai_healthcode]
    db_connection.upload_voice_generator_ai_data(self.user_id, iteration_id, conversation_id, input_text, audio_file_key, timestamp_input, timestamp_output, healthcode)
  
    update_conversation_table(db_connection, conversation_id)
  end
end 

class ActiveUserList
  attr_accessor :list

  def initialize
    @list = {}
  end

  def add_user(google_auth, db_connection)
    user = User.new(google_auth, db_connection)
    @list[user.user_id] = user
    user.user_id
  end

  def load_user(user_id)
    list[user_id]
  end

end