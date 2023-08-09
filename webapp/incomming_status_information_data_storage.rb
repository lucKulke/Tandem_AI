class IncommingStatusInformationData
  attr_accessor :bucket
  
  def initialize
    @bucket = {}
  end
  
  def create_iteration_temp_storage(user_id, conversation)
    self.bucket[user_id] = {conversation: conversation, ai_audio_file_on_server: nil} 
  end

  def delete_iteration_temp_storage
    self.bucket.delete(user_id)
  end

  def save_speech_recognition_transcription_ai_data(user_id, audio_file_key: nil, output_text: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.bucket[user_id][:audio_file_key] = audio_file_key
    self.bucket[user_id][:output_text] = output_text
    self.bucket[user_id][:timestamp_input] = timestamp_input
    self.bucket[user_id][:timestamp_output] = timestamp_output
    self.bucket[user_id][:healthcode] = healthcode 
  end

  def save_language_processing_ai_data(user_id, input_text: nil, output_text: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.bucket[user_id][:input_text] = input_text
    self.bucket[user_id][:output_text] = output_text
    self.bucket[user_id][:timestamp_input] = timestamp_input
    self.bucket[user_id][:timestamp_output] = timestamp_output
    self.bucket[user_id][:healthcode] = healthcode
  end

  def save_voice_generation_ai_data_output(user_id, input_text: nil, audio_file_key: nil, timestamp_input: nil, timestamp_output: nil, health_code: nil)
    self.bucket[user_id][:input_text] = input_text
    self.bucket[user_id][:audio_file_key] = audio_file_key
    self.bucket[user_id][:timestamp_input] = timestamp_input
    self.bucket[user_id][:timestamp_output] = timestamp_output
    self.bucket[user_id][:healthcode] = healthcode
  end
end

