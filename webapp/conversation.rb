class Conversation
  attr_accessor :iteration, :user_labelling, :ai_labelling, :conversation_text, :name, :data, :conversation_id, :sections
  
  def initialize(conversation_id, text, sections, name, user_labelling, ai_labelling)
    @conversation_id = conversation_id
    @sections = sections
    @conversation_text = conversation_text
    @user_labelling = user_labelling
    @ai_labelling = ai_labelling
    @name = name
    reset
  end

  def reset
    @data = {
      speech_recognition_transcription_ai_audio_file_key: nil,
      speech_recognition_transcription_ai_output_text: nil,
      speech_recognition_transcription_ai_timestamp_input: nil,
      speech_recognition_transcription_ai_timestamp_output: nil,
      speech_recognition_transcription_ai_healthcode: nil,
      language_processing_ai_input_text: nil,
      language_processing_ai_output_text: nil,
      language_processing_ai_timestamp_input: nil,
      language_processing_ai_timestamp_output: nil,
      language_processing_ai_healthcode: nil,
      voice_generator_ai_input_text: nil,
      voice_generator_ai_audio_file_key: nil,
      voice_generator_ai_timestamp_input: nil,
      voice_generator_ai_timestamp_output: nil,
      voice_generator_ai_healthcode: nil
    }
  end


  def client_information
    {audio_file_key: self.data[:voice_generator_ai_audio_file_key], user_text: self.data[:speech_recognition_transcription_ai_output_text], ai_answer: self.data[:language_processing_ai_output_text], conversation: sections}
  end


  def save_speech_recognition_transcription_ai_data(user_id, audio_file_key: nil, output_text: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.data[:speech_recognition_transcription_ai_audio_file_key] = audio_file_key
    self.data[:speech_recognition_transcription_ai_output_text] = output_text
    self.data[:speech_recognition_transcription_ai_timestamp_input] = timestamp_input
    self.data[:speech_recognition_transcription_ai_timestamp_output] = timestamp_output
    self.data[:speech_recognition_transcription_ai_healthcode] = healthcode 
  end

  def save_language_processing_ai_data(user_id, input_text: nil, output_text: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.data[:language_processing_ai_input_text] = input_text
    self.data[:language_processing_ai_output_text] = output_text
    self.data[:language_processing_ai_timestamp_input] = timestamp_input
    self.data[:language_processing_ai_timestamp_output] = timestamp_output
    self.data[:language_processing_ai_healthcode] = healthcode
  end

  def save_voice_generator_ai_data(user_id, input_text: nil, audio_file_key: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.data[:voice_generator_ai_input_text] = input_text
    self.data[:voice_generator_ai_audio_file_key] = audio_file_key
    self.data[:voice_generator_ai_timestamp_input] = timestamp_input
    self.data[:voice_generator_ai_timestamp_output] = timestamp_output
    self.data[:voice_generator_ai_healthcode] = healthcode
  end
  
end