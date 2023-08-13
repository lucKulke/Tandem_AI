require_relative 'conversation'
require_relative './database/database_connection'
require 'date'

class User
  attr_accessor :current_conversation, :current_conversation_id, :conversations
  attr_reader :user_id

  def initialize(first_name, surname, email, db_connection)
    @user_id = load_user_data(first_name, surname, email, db_connection)
    @current_conversation_id = nil
    @current_conversation = nil
  end

  def create_conversation(db_connection)
    conversation_name = 'new Conversation'
    uuid = db_connection.query('SELECT UUID();').first['UUID()']
    start_text = ''
    db_connection.query("INSERT INTO conversations(user_id, conversation_id, conversation_name , conversation, timestamp_start) VALUES('#{self.user_id}', '#{uuid}', '#{conversation_name}', '#{start_text}', '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}')")
    new_conversation = Conversation.new(uuid, start_text, conversation_name, 'User:', 'AI:')
    conversations << new_conversation
  end

  def delete_conversation(conversation_id)
    conversations.delete_if{|conversation| conversation.conversation_id == conversation_id}
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

  def update_conversation_data(iteration_information_obj)
    iteration_information_obj.bucket[user_id].each do |key, value|
      if key == :conversation_text
        current_conversation.conversation_text = value
      else
        current_conversation.conversation_data[key] = value
      end
    end
  end

  def create_uuid(db_connection)
    db_connection.query('SELECT UUID();').first['UUID()']
  end

  def load_user_data(first_name, surname, email, db_connection)
    user_id = search_user_id(first_name, surname, email, db_connection)
    if user_id.empty?
      user_id = create_user_in_db(first_name, surname, email, db_connection)
      @conversations = []
    else
      @conversations = load_conversations(user_id, db_connection)
    end
    user_id
  end

  def load_conversations(user_id, db_connection)
    return_format = []
    result = db_connection.query("SELECT conversation_id, conversation_name, conversation FROM conversations WHERE user_id = '#{user_id}';")
    
    result.each do |row|
      return_format << Conversation.new(row['conversation_id'], row['conversation'], row['conversation_name'], 'User:', 'AI:')
    end
    return_format
  end


  def create_user_in_db(first_name, surname, email, db_connection)
    uuid = db_connection.query('SELECT UUID();').first['UUID()']
    db_connection.query("INSERT INTO users VALUES ('#{uuid}','#{first_name}','#{surname}','#{email}');")
    uuid # returns user_id
  end

  def search_user_id(first_name, surname, email, db_connection)
    result = db_connection.query("SELECT user_id FROM users WHERE first_name = '#{first_name}' AND surname = '#{surname}' AND email = '#{email}';") #AND surname = #{surname} AND email = #{email}
    result.first.nil? ? [] : result.first['user_id']
  end

  def update_conversation_table(db_connection, conversation_id)
    name = db_connection.escape(current_conversation.name)
    conversation_text = db_connection.escape(current_conversation.conversation_text)
    db_connection.query("UPDATE conversations SET conversation = '#{conversation_text}', conversation_name = '#{name}' WHERE conversation_id = '#{conversation_id}';")
  end

 
  def upload_conversation_to_db(conversation_id, db_connection)
    iteration_id = create_uuid(db_connection)
    data = current_conversation.conversation_data
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
    output_text = db_connection.escape(data[:language_processing_ai_output_text])
    db_connection.query("INSERT INTO language_processing_ai 
                        (user_id, iteration_id, conversation_id, input_text, output_text, timestamp_input, timestamp_output, healthcode) 
                        VALUES('#{user_id}', '#{iteration_id}', '#{conversation_id}', '#{input_text}', '#{output_text}',
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

  def add_user(first_name, surname, email, db_connection)
    user = User.new(first_name, surname, email, db_connection)
    @list[user.user_id] = user
    user.user_id
  end

  def load_user(user_id)
    list[user_id]
  end

end