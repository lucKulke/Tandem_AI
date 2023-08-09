require_relative 'conversation'
require_relative './database/database_connection'

class User
  attr_accessor :current_conversation, :current_conversation_id
  attr_reader :user_id, :db_connection, :conversations

  def initialize(first_name, surname, email)
    @db_connection = DatabaseConnection.new.establish
    @user_id = load_user_id(first_name, surname, email)
    @conversations = load_conversation_id_and_text(user_id)
    @current_conversation_id = nil
    @current_conversation = nil
  end

  def enter_conversation(conversation_id)
    self.current_conversation_id = conversation_id
    conversation = load_conversation_text(conversation_id)
    self.current_conversation = Conversation.new(conversation_id, conversation)
  end

  def update_conversation_data(status_obj)
    values = status_obj[self.user_id]
    values.each do |key, value|
      self.current_conversation[key] = value
    end
  end

  private 


  def search_user_id(first_name, surname, email)
    result = db_connection.query("SELECT user_id
                        FROM users
                        WHERE first_name = #{first_name} && surname = #{surname} && email = #{email};")
    
    result.each{ |row| return row['user_id'] }
  end


  def load_conversation_id_and_text(user_id)
    return_format = {}
    result = db_connection.query("SELECT conversation_id, conversation
                        FROM conversations
                        WHERE user_id = #{user_id};")
    
    result.each do |row|
      return_format[row["conversation_id"]] = row["conversation"]
    end
    return_format
  end

  def load_conversation_text(conversation_id)
    self.conversations[conversation_id]
  end

  def upload_conversation_to_db(conversation_id)
    
    # loads each iteration in each ai table
    (1..current_conversation.iteration).each do |iteration|
      speech_recognition_transcription_ai_row = current_conversation.speech_recognition_transcription_ai_data[iteration]
      db_connection.query("INSERT INTO speech_recognition_transcription_ai
                          (user_id, iteration, conversation_id, input_audio_file_ref, output, timestamp_input, timestamp_output, health_code)
                          VALUES(#{user_id}, #{iteration}, #{conversation_id}, #{speech_recognition_transcription_ai_row[:speech_recognition_transcription_audio_file_key]},
                          #{speech_recognition_transcription_ai_row[:speech_recognition_transcription_output]}, #{speech_recognition_transcription_ai_row[:speech_recognition_transcription_timestamp_input]}, 
                          #{speech_recognition_transcription_ai_row[:speech_recognition_transcription_timestamp_output]}, #{speech_recognition_transcription_ai_row[:speech_recognition_transcription_healthcode]})")
      
      language_processing_ai_row = current_conversation.language_processing_ai_data[iteration]
      db_connection.query("INSERT INTO language_processing_ai
                          (user_id, iteration, conversation_id, input_audio_file_ref, output, timestamp_input, timestamp_output, health_code)
                          VALUES(#{user_id}, #{iteration}, #{conversation_id}, #{language_processing_ai_row[:language_processing_input]},
                          #{language_processing_ai_row[:language_processing_output]}, #{language_processing_ai_row[:language_processing_timestamp_input]}, 
                          #{language_processing_ai_row[:language_processing_timestamp_output]}, #{language_processing_ai_row[:language_processing_healthcode]})")
                        
      voice_generator_ai_row = current_conversation.voice_generator_ai_data[iteration]
      db_connection.query("INSERT INTO voice_generator_ai
                          (user_id, iteration, conversation_id, input_audio_file_ref, output, timestamp_input, timestamp_output, health_code)
                          VALUES(#{user_id}, #{iteration}, #{conversation_id}, #{voice_generator_ai_row[:voice_generator_input]},
                          #{voice_generator_ai_row[:voice_generator_audio_file_key]}, #{voice_generator_ai_row[:voice_generator_timestamp_input]}, 
                          #{voice_generator_ai_row[:voice_generator_timestamp_output]}, #{voice_generator_ai_row[:voice_generator_healthcode]})")

      # update conversation table
      db_connection.query("UPDATE conversations SET conversation = #{current_conversation.conversation_text} WHERE conversation_id = #{conversation_id}")
  end
end