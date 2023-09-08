class RedisConnection
  attr_reader :logger, :redis

  def initialize(host = 'localhost', port = 6379, db = 0, logger = nil)
    @logger = logger
    connect_to_redis_server(host, port, db)
  end

  def set(key, value)
    redis.set(key, value)
  end
  
  def get(key)
    redis.get(key)
  end

  def del(key)
    redis.del(key)
  end

  def reset_cache_for_user(user_id)
    self.del("speech_recognition_transcription_ai_audio_file_key_#{user_id}")
    self.del("speech_recognition_transcription_ai_output_text_#{user_id}")
    self.del("language_processing_ai_interlocutor_output_text_#{user_id}")
    self.del("language_processing_ai_corrector_output_text_#{user_id}")
    self.del("voice_generator_ai_audio_file_key_#{user_id}")
  end

  def create_cache(user_id, conversation_id, interlocutor_sections, corrector_sections)
    self.set("interlocutor_sections_#{user_id}", interlocutor_sections.to_json)
    self.set("corrector_sections_#{user_id}", corrector_sections.to_json)
    self.set("conversation_id_#{user_id}", conversation_id) unless conversation_id.nil?
  end

  def update_sections(user_id, interlocutor_sections, corrector_sections)
    self.create_cache(user_id, nil, interlocutor_sections, corrector_sections)
  end

  def connect_to_redis_server(host, port, db)
    retry_time = 5
    begin
      retries ||= 0
      @redis = Redis.new(host: host, port: port, db: db)
    rescue Exeption => e
      logger.error("Redis connecting error: #{e} \nRetry in #{retry_time}")
      sleep retry_time
      retries += 1
      retry unless retries == 3
      raise Exeption, e
    end
    logger.info("Connected to redis server!")
  end

end