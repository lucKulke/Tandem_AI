require "mysql2"

class DatabaseConnection
  attr_reader :establish

  DB_CONFIG = {
    host: 'localhost',
    port: '3206',
    username: 'root',
    password: 'halkopo2',
    database: 'tandem_ai'
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
      first_name VARCHAR(100),
      surname VARCHAR(100),
      email VARCHAR(300));")
    
    @db.query("CREATE TABLE IF NOT EXISTS conversations(
      user_id VARCHAR(50),
      conversation_id VARCHAR(50),
      conversation MEDIUMTEXT,
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
      output_text VARCHAR(1000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    @db.query("CREATE TABLE IF NOT EXISTS voice_generator_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      input_text VARCHAR(1000),
      audio_file_key VARCHAR(1000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    @db.query("CREATE TABLE IF NOT EXISTS language_processing_ai(
      user_id VARCHAR(50),
      iteration_id VARCHAR(50),
      conversation_id VARCHAR(50),
      input_text VARCHAR(1000),
      output_text VARCHAR(1000),
      timestamp_input DATETIME,
      timestamp_output DATETIME,
      healthcode INT);")
    
    @db
    end
end


