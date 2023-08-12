class IncommingStatusInformationData
  attr_accessor :bucket
  
  def initialize
    @bucket = {}
  end
  
  def create_iteration_temp_storage(user_id, conversation)
    self.bucket[user_id] = {conversation: conversation} 
  end

  def delete_iteration_temp_storage(user_id)
    self.bucket.delete(user_id)
  end

  def save_speech_recognition_transcription_ai_data(user_id, audio_file_key: nil, output_text: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.bucket[user_id][:speech_recognition_transcription_ai_audio_file_key] = audio_file_key
    self.bucket[user_id][:speech_recognition_transcription_ai_output_text] = output_text
    self.bucket[user_id][:speech_recognition_transcription_ai_timestamp_input] = timestamp_input
    self.bucket[user_id][:speech_recognition_transcription_ai_timestamp_output] = timestamp_output
    self.bucket[user_id][:speech_recognition_transcription_ai_healthcode] = healthcode 
  end

  def save_language_processing_ai_data(user_id, input_text: nil, output_text: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.bucket[user_id][:language_processing_ai_input_text] = input_text
    self.bucket[user_id][:language_processing_ai_output_text] = output_text
    self.bucket[user_id][:language_processing_ai_timestamp_input] = timestamp_input
    self.bucket[user_id][:language_processing_ai_timestamp_output] = timestamp_output
    self.bucket[user_id][:language_processing_ai_healthcode] = healthcode
  end

  def save_voice_generation_ai_data(user_id, input_text: nil, audio_file_key: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.bucket[user_id][:voice_generator_ai_input_text] = input_text
    self.bucket[user_id][:voice_generator_ai_audio_file_key] = audio_file_key
    self.bucket[user_id][:voice_generator_ai_timestamp_input] = timestamp_input
    self.bucket[user_id][:voice_generator_ai_timestamp_output] = timestamp_output
    self.bucket[user_id][:voice_generator_ai_healthcode] = healthcode
  end
end

