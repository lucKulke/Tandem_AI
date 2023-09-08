require "mysql2"

class DatabaseConnection
  attr_reader :logger

  def initialize(db_config, logger)
    @logger = logger
    connect_to_db(db_config)
  end

  def connect_to_db(db_config)
    retry_time = 5
    begin
      retries ||= 0
      @db = Mysql2::Client.new(DB_CONFIG)
    rescue Mysql2::Error => e
      logger.error("Mysql connection error: #{e} \nRetry in #{retry_time}")
      sleep retry_time
      retries += 1
      retry unless retries == 3
      raise Mysql2:Error      
    end
    logger.info("Connected to Mysql db!")
  end

  def establish
    self.db
  end

  def create_tables
    query("CREATE TABLE IF NOT EXISTS users(
      user_id VARCHAR(50),
      google_auth VARCHAR(120));")
    
    query("CREATE TABLE IF NOT EXISTS conversations(
      user_id VARCHAR(50),
      conversation_id VARCHAR(50),
      conversation_name VARCHAR(80),
      conversation_picture VARCHAR(100),
      timestamp_start DATETIME,
      timestamp_paused DATETIME,
      timestamp_joined DATETIME,
      timestamp_deleted DATETIME,
      status_code INT);")
    
    query("CREATE TABLE IF NOT EXISTS iteration_data(
      user_id VARCHAR(50),
      conversation_id VARCHAR(50),
      iteration_id VARCHAR(50),
      speech_recognition_transcription_ai_audio_file_key VARCHAR(255),
      speech_recognition_transcription_ai_output_text VARCHAR(2000),
      language_processing_ai_interlocutor_output_text VARCHAR(2000),
      language_processing_ai_corrector_output_text VARCHAR(2000),
      voice_generator_ai_audio_file_key VARCHAR(255)
      );")
    
  end

  def escape(string)
    self.db.escape(string)
  end


  def create_uuid
    query('SELECT UUID();').first['UUID()']
  end

  def query(query)
    self.db.query(query)
  end

  def create_user(google_auth, uuid)
    query("INSERT INTO users VALUES ('#{uuid}','#{google_auth}');")
    uuid 
  end

  def update_iteration_data(user_id, conversation_id, iteration_id, iteration_obj)
    p iteration_obj
    user_text = escape(iteration_obj.speech_recognition_transcription_ai_output_text)
    interlocutor_output_text = escape(iteration_obj.language_processing_ai_interlocutor_output_text)
    corrector_output_text = escape(iteration_obj.language_processing_ai_corrector_output_text)
    query("INSERT INTO iteration_data VALUES('#{user_id}', '#{conversation_id}', '#{iteration_id}', '#{iteration_obj.speech_recognition_transcription_ai_audio_file_key}', '#{user_text}', '#{interlocutor_output_text}', '#{corrector_output_text}', '#{iteration_obj.voice_generator_ai_audio_file_key}')")
  end

  def search_user_id(google_auth)
    result = query("SELECT user_id FROM users WHERE google_auth = '#{google_auth}';")
    result.first.nil? ? [] : result.first['user_id']
  end
  
  def create_conversation(user_id, conversation_id, name, default_picture, timestamp, status_code)
    name = escape(name)
    query("INSERT INTO conversations(user_id, conversation_id, conversation_name, conversation_picture, timestamp_start, status_code) VALUES('#{user_id}', '#{conversation_id}', '#{name}', '#{default_picture}', '#{timestamp}', '#{status_code}')")
  end

  def delete_conversation(conversation_id, status_code, timestamp)
    query("UPDATE conversations SET status_code = '#{status_code}', timestamp_deleted = '#{timestamp}' WHERE conversation_id = '#{conversation_id}';")
  end
  
  def select_conversation_id_and_name_and_picture(user_id, status_code)
    query("SELECT conversation_id, conversation_name, conversation_picture FROM conversations WHERE user_id = '#{user_id}' AND status_code = '#{status_code}';")
  end

  def load_interlocutor_sections(conversation_id)
    p conversation_id
    sections = []
    result = query("SELECT speech_recognition_transcription_ai_output_text, language_processing_ai_interlocutor_output_text FROM iteration_data WHERE conversation_id = '#{conversation_id}'")
    result.each do |row|
      p row
      sections << {'role' => 'user', 'content' => row['speech_recognition_transcription_ai_output_text']}
      sections << {'role' => 'assistant', 'content' => row['language_processing_ai_interlocutor_output_text']}
    end
    sections
  end

  def load_corrector_sections(conversation_id)
    sections = []
    result = query("SELECT speech_recognition_transcription_ai_output_text, language_processing_ai_corrector_output_text FROM iteration_data WHERE conversation_id = '#{conversation_id}'")
    result.each do |row|
      sections << {'role' => 'user', 'content' => row['speech_recognition_transcription_ai_output_text']}
      sections << {'role' => 'assistant', 'content' => row['language_processing_ai_corrector_output_text']}
    end
    sections
  end

  def update_conversation_name(conversation_id, name)
    name = escape(name)
    query("UPDATE conversations SET conversation_name = '#{name}' WHERE conversation_id = '#{conversation_id}'")
  end

  def update_conversation_picture(conversation_id, picture)
    query("UPDATE conversations SET conversation_picture = '#{picture}' WHERE conversation_id = '#{conversation_id}'")
  end


  private

  attr_reader :db

end
#DateTime.now.strftime('%Y-%m-%d %H:%M:%S')


