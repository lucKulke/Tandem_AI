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

  def create_conversation(db_connection)
    conversation_name = 'new Conversation'
    uuid = db_connection.query('SELECT UUID();').first['UUID()']
    start_text = 'conversation start: '
    db_connection.query("INSERT INTO conversations(user_id, conversation_id, conversation_name , interlocutor_conversation, corrector_conversation, timestamp_start, status_code) VALUES('#{self.user_id}', '#{uuid}', '#{conversation_name}', '#{start_text}', '#{start_text}','#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}', 200)")
    self.conversations << Conversation.new(uuid, [], [], conversation_name, 'User:', 'AI:')
  end

  def delete_conversation(conversation_id, db_connection)
    conversations.delete_if{|conversation| conversation.conversation_id == conversation_id}
    db_connection.query("UPDATE conversations SET status_code = 404, timestamp_deleted = '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}' WHERE conversation_id = '#{conversation_id}';")
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


  def create_uuid(db_connection)
    db_connection.query('SELECT UUID();').first['UUID()']
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
    result = db_connection.query("SELECT conversation_id, conversation_name FROM conversations WHERE user_id = '#{user_id}' AND status_code = 200;")
    result.each do |row|
      interlocutor_sections = load_interlocutor_sections(row['conversation_id'], db_connection)
      corrector_sections = load_corrector_sections(row['conversation_id'], db_connection)
      return_format << Conversation.new(row['conversation_id'], interlocutor_sections, corrector_sections, row['conversation_name'], 'User:', 'AI:')
    end
    return_format
  end

  def load_interlocutor_sections(conversation_id, db_connection)
    sections = []
    id = db_connection.escape(conversation_id)
    result = db_connection.query("SELECT input_text, interlocutor_output_text FROM language_processing_ai WHERE conversation_id = '#{id}'")
    result.each do |row|
      sections << {role: 'user', content: row['input_text']}
      sections << {role: 'system', content: row['interlocutor_output_text']}
    end
    sections
  end

  def load_corrector_sections(conversation_id, db_connection)
    sections = []
    id = db_connection.escape(conversation_id)
    result = db_connection.query("SELECT input_text, corrector_output_text FROM language_processing_ai WHERE conversation_id = '#{id}'")
    result.each do |row|
      sections << {role: 'user', content: row['input_text']}
      sections << {role: 'system', content: row['corrector_output_text']}
    end
    sections
  end


  def create_user_in_db(google_auth, db_connection)
    uuid = db_connection.query('SELECT UUID();').first['UUID()']
    db_connection.query("INSERT INTO users VALUES ('#{uuid}','#{google_auth}');")
    uuid # returns user_id
  end

  def search_user_id(google_auth, db_connection)
    result = db_connection.query("SELECT user_id FROM users WHERE google_auth = '#{google_auth}';")
    result.first.nil? ? [] : result.first['user_id']
  end

  def update_conversation_table(db_connection, conversation_id)
    name = db_connection.escape(current_conversation.name)
    interlocutor_text = db_connection.escape(convert_to_text(current_conversation.interlocutor_sections))
    corrector_text = db_connection.escape(convert_to_text(current_conversation.corrector_sections))

    db_connection.query("UPDATE conversations SET interlocutor_conversation = '#{interlocutor_text}', corrector_conversation = '#{corrector_text}', conversation_name = '#{name}' WHERE conversation_id = '#{conversation_id}';")
  end

  def convert_to_text(conversation)
    text = 'conversation start: '
    conversation.each do |row|
      text += "#{row[:role]}: #{row[:content]} "
    end
    text
  end

 
  def upload_conversation_to_db(db_connection)
    iteration_id = create_uuid(db_connection)
    conversation_id = self.current_conversation_id
    data = self.current_conversation.data
    output_text = db_connection.escape(data[:speech_recognition_transcription_ai_output_text])
    db_connection.query("INSERT INTO speech_recognition_transcription_ai
                        (user_id, iteration_id, conversation_id, audio_file_key, output_text, timestamp_input, timestamp_output, healthcode)
                        VALUES('#{user_id}', '#{iteration_id}', '#{conversation_id}', 
                        '#{data[:speech_recognition_transcription_ai_audio_file_key]}',
                        '#{output_text}',
                        '#{data[:speech_recognition_transcription_ai_timestamp_input]}', 
                        '#{data[:speech_recognition_transcription_ai_timestamp_output]}',
                        '#{data[:speech_recognition_transcription_ai_healthcode].to_i}');")
                                      
    input_text = db_connection.escape(data[:language_processing_ai_input_text])
    interlocutor_output_text = db_connection.escape(data[:language_processing_ai_interlocutor_output_text])
    corrector_output_text = db_connection.escape(data[:language_processing_ai_corrector_output_text])
    db_connection.query("INSERT INTO language_processing_ai 
                        (user_id, iteration_id, conversation_id, input_text, interlocutor_output_text, corrector_output_text, timestamp_input, timestamp_output, healthcode) 
                        VALUES('#{user_id}', '#{iteration_id}', '#{conversation_id}', '#{input_text}', '#{interlocutor_output_text}', '#{corrector_output_text}',
                        '#{data[:language_processing_ai_timestamp_input]}', 
                        '#{data[:language_processing_ai_timestamp_output]}', 
                        '#{data[:language_processing_ai_healthcode].to_i}');")
                        
    input_text = db_connection.escape(data[:voice_generator_ai_input_text])
    db_connection.query("INSERT INTO voice_generator_ai
                        (user_id, iteration_id, conversation_id, input_text, audio_file_key, timestamp_input, timestamp_output, healthcode)
                        VALUES('#{user_id}', '#{iteration_id}', '#{conversation_id}',
                        '#{input_text}',
                        '#{data[:voice_generator_ai_audio_file_key]}',
                        '#{data[:voice_generator_ai_timestamp_input]}', 
                        '#{data[:voice_generator_ai_timestamp_output]}',
                        '#{data[:voice_generator_ai_healthcode].to_i}');")

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