class Conversation
  attr_accessor :iteration, :user_labelling, :ai_labelling, :name, :data, :conversation_id, :interlocutor_sections, :corrector_sections, :picture, :picture_changed
  
  def initialize(conversation_id, interlocutor_sections, corrector_sections, name, user_labelling, ai_labelling, picture)
    @conversation_id = conversation_id
    @interlocutor_sections = interlocutor_sections
    @corrector_sections = corrector_sections
    @user_labelling = user_labelling
    @ai_labelling = ai_labelling
    @picture = picture
    @name = name
    @picture_changed = false
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
    {audio_file_key: self.data[:voice_generator_ai_audio_file_key], user_text: self.data[:speech_recognition_transcription_ai_output_text], ai_answer: self.data[:language_processing_ai_interlocutor_output_text], section: self.last_added_section}
  end

  def last_added_section
    [
      [{role: 'user', content: data[:language_processing_ai_input_text] }, {role: 'assistant', content: data[:language_processing_ai_corrector_output_text]}],
      {role: 'assistant', content: data[:language_processing_ai_interlocutor_output_text]}
    ] 
  end


  def save_speech_recognition_transcription_ai_data(user_id, audio_file_key: nil, output_text: nil, timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.data[:speech_recognition_transcription_ai_audio_file_key] = audio_file_key unless audio_file_key.nil?
    self.data[:speech_recognition_transcription_ai_output_text] = output_text
    self.data[:speech_recognition_transcription_ai_timestamp_input] = timestamp_input
    self.data[:speech_recognition_transcription_ai_timestamp_output] = timestamp_output
    self.data[:speech_recognition_transcription_ai_healthcode] = healthcode 
  end

  def save_language_processing_ai_data(user_id, input_text: nil, interlocutor_output_text: nil, corrector_output_text: nil,timestamp_input: nil, timestamp_output: nil, healthcode: nil)
    self.data[:language_processing_ai_input_text] = input_text
    self.data[:language_processing_ai_interlocutor_output_text] = interlocutor_output_text
    self.data[:language_processing_ai_corrector_output_text] = corrector_output_text
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