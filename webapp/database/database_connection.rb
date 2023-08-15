require "mysql2"

class DatabaseConnection
  attr_reader :establish

  DB_CONFIG = {
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT'],
    username: ENV['DB_USERNAME'],
    password: ENV['DB_PASSWORD'],
    database: ENV['DB_NAME']
  }

  def initialize
    @db = Mysql2::Client.new(DB_CONFIG)
  end

  def establish
    @db
  end

  def create_tables
    @db.query("CREATE TABLE IF NOT EXISTS users(
      user_id VARCHAR(50),
      google_auth VARCHAR(120));")
    
    @db.query("CREATE TABLE IF NOT EXISTS conversations(
      user_id VARCHAR(50),
      conversation_id VARCHAR(50),
      conversation_name VARCHAR(80),
      interlocutor_conversation MEDIUMTEXT,
      corrector_conversation MEDIUMTEXT,
      timestamp_start DATETIME,
      timestamp_paused DATETIME,
      timestamp_joined DATETIME,
      timestamp_deleted DATETIME,
      status_code INT);")
    
    @db.query("CREATE TABLE IF NOT EXISTS speech_recognition_transcription_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      audio_file_key VARCHAR(255),
      output_text VARCHAR(2000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    @db.query("CREATE TABLE IF NOT EXISTS voice_generator_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      input_text VARCHAR(2000),
      audio_file_key VARCHAR(2000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    @db.query("CREATE TABLE IF NOT EXISTS language_processing_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      input_text VARCHAR(2000),
      interlocutor_output_text VARCHAR(2000),
      corrector_output_text VARCHAR(2000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    @db
    end
end


