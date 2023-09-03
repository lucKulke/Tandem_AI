require "mysql2"

class DatabaseConnection

  DB_CONFIG = {
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT'],
    username: ENV['DB_USERNAME'],
    password: ENV['DB_PASSWORD'],
    database: ENV['DB_NAME']
  }

  def initialize
    begin
      retries ||= 0
      @db = Mysql2::Client.new(DB_CONFIG)
    rescue Mysql2::Error => e
      puts e
      puts "MySQL server not ready yet, retrying in 20 second "
      sleep 20
      retries += 1
      if retries == 3
        retry
      end
      
    end
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
      interlocutor_conversation MEDIUMTEXT,
      corrector_conversation MEDIUMTEXT,
      timestamp_start DATETIME,
      timestamp_paused DATETIME,
      timestamp_joined DATETIME,
      timestamp_deleted DATETIME,
      status_code INT);")
    
    query("CREATE TABLE IF NOT EXISTS speech_recognition_transcription_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      audio_file_key VARCHAR(255),
      output_text VARCHAR(2000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    query("CREATE TABLE IF NOT EXISTS voice_generator_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      input_text VARCHAR(2000),
      audio_file_key VARCHAR(2000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    query("CREATE TABLE IF NOT EXISTS language_processing_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      input_text VARCHAR(2000),
      interlocutor_output_text VARCHAR(2000),
      corrector_output_text VARCHAR(2000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
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

  def search_user_id(google_auth)
    result = query("SELECT user_id FROM users WHERE google_auth = '#{google_auth}';")
    result.first.nil? ? [] : result.first['user_id']
  end
  
  def create_conversation(user_id, conversation_id, name, default_picture, start_text, timestamp, status_code)
    name = escape(name)
    start_text = escape(start_text)
    query("INSERT INTO conversations(user_id, conversation_id, conversation_name, conversation_picture, interlocutor_conversation, corrector_conversation, timestamp_start, status_code) VALUES('#{user_id}', '#{conversation_id}', '#{name}', '#{default_picture}','#{start_text}', '#{start_text}','#{timestamp}', '#{status_code}')")
  end

  def delete_conversation(conversation_id, status_code, timestamp)
    query("UPDATE conversations SET status_code = '#{status_code}', timestamp_deleted = '#{timestamp}' WHERE conversation_id = '#{conversation_id}';")
  end
  
  def select_conversation_id_and_name_and_picture(user_id, status_code)
    query("SELECT conversation_id, conversation_name, conversation_picture FROM conversations WHERE user_id = '#{user_id}' AND status_code = '#{status_code}';")
  end

  def load_interlocutor_sections(conversation_id)
    sections = []
    result = query("SELECT input_text, interlocutor_output_text FROM language_processing_ai WHERE conversation_id = '#{conversation_id}'")
    result.each do |row|
      sections << {role: 'user', content: row['input_text']}
      sections << {role: 'assistant', content: row['interlocutor_output_text']}
    end
    sections
  end

  def load_corrector_sections(conversation_id)
    sections = []
    result = query("SELECT input_text, corrector_output_text FROM language_processing_ai WHERE conversation_id = '#{conversation_id}'")
    result.each do |row|
      sections << {role: 'user', content: row['input_text']}
      sections << {role: 'assistant', content: row['corrector_output_text']}
    end
    sections
  end

  def update_conversation_table(conversation_id, name, picture,interlocutor_text, corrector_text)
    name = escape(name)
    interlocutor_text = escape(interlocutor_text)
    corrector_text = escape(corrector_text)
    query("UPDATE conversations SET interlocutor_conversation = '#{interlocutor_text}', corrector_conversation = '#{corrector_text}', conversation_name = '#{name}', conversation_picture = '#{picture}' WHERE conversation_id = '#{conversation_id}';")
  end

  def update_conversation_picture(conversation_id, picture)
    query("UPDATE conversations SET conversation_picture = '#{picture}' WHERE conversation_id = '#{conversation_id}'")
  end

  def upload_speech_recognition_transcription_ai_data(user_id, iteration_id, conversation_id, audio_file_key, output_text, timestamp_input, timestamp_output, healthcode)
    output_text = escape(output_text)
    query("INSERT INTO speech_recognition_transcription_ai
                        (user_id, iteration_id, conversation_id, audio_file_key, output_text, timestamp_input, timestamp_output, healthcode)
                        VALUES('#{user_id}', '#{iteration_id}', '#{conversation_id}', 
                        '#{audio_file_key}',
                        '#{output_text}',
                        '#{timestamp_input}', 
                        '#{timestamp_output}',
                        '#{healthcode}');")
  end

  def upload_language_processing_ai_data(user_id, iteration_id, conversation_id, input_text, interlocutor_output_text, corrector_output_text, timestamp_input, timestamp_output, healthcode)
    input_text = escape(input_text)
    interlocutor_output_text = escape(interlocutor_output_text)
    corrector_output_text = escape(corrector_output_text)
    query("INSERT INTO language_processing_ai 
                        (user_id, iteration_id, conversation_id, input_text, interlocutor_output_text, corrector_output_text, timestamp_input, timestamp_output, healthcode) 
                        VALUES('#{user_id}', '#{iteration_id}', '#{conversation_id}', '#{input_text}', '#{interlocutor_output_text}', '#{corrector_output_text}',
                        '#{timestamp_input}', 
                        '#{timestamp_output}', 
                        '#{healthcode}');")
  end

  def upload_voice_generator_ai_data(user_id, iteration_id, conversation_id, input_text, audio_file_key, timestamp_input, timestamp_output, healthcode)
    input_text = escape(input_text)
    query("INSERT INTO voice_generator_ai
                        (user_id, iteration_id, conversation_id, input_text, audio_file_key, timestamp_input, timestamp_output, healthcode)
                        VALUES('#{user_id}', '#{iteration_id}', '#{conversation_id}',
                        '#{input_text}',
                        '#{audio_file_key}',
                        '#{timestamp_input}', 
                        '#{timestamp_output}',
                        '#{healthcode}');")
  end


  private

  attr_reader :db

end
#DateTime.now.strftime('%Y-%m-%d %H:%M:%S')


