class IncommingStatusInformationData
  attr_accessor :bucket
  
  def initialize
    @bucket = {}
  end
  
  def create_iteration_temp_storage(user_id)
    self.bucket[user_id] = {} 
  end

  def delete_iteration_temp_storage
    self.bucket.delete(user_id)
  end

  def save_speech_recognition_transcription_ai_data_input(user_id, audio_file_key, timestamp)
    self.bucket[user_id][:speech_recognition_transcription_audio_file_key] = audio_file_key
    self.bucket[user_id][:speech_recognition_transcription_timestamp_input] = timestamp
  end

  def save_speech_recognition_transcription_ai_data_output(user_id, output, timestamp, healthcode)
    self.bucket[user_id][:speech_recognition_transcription_output] = output
    self.bucket[user_id][:speech_recognition_transcription_timestamp_output] = timestamp
    self.bucket[user_id][:speech_recognition_transcription_healthcode] = healthcode
  end

  def save_voice_generation_ai_data_output(user_id, audio_file_key, timestamp, health_code)
    self.bucket[user_id][:voice_generator_audio_file_key] = audio_file_key
    self.bucket[user_id][:voice_generator_timestamp_output] = timestamp
    self.bucket[user_id][:voice_generator_healthcode] = healthcode
  end
end

