class Conversation
  attr_accessor :iteration, :name, :data, :conversation_id, :interlocutor_sections, :corrector_sections, :picture, :picture_changeable
  
  def initialize(conversation_id, interlocutor_sections, corrector_sections, name, picture, picture_changeable)
    @conversation_id = conversation_id
    @interlocutor_sections = interlocutor_sections
    @corrector_sections = corrector_sections
    @user_labelling = user_labelling
    @ai_labelling = ai_labelling
    @picture = picture
    @name = name
    @picture_changeable = picture_changeable
    reset
  end

  def reset
    @data = {
      speech_recognition_transcription_ai_audio_file_key: nil,
      speech_recognition_transcription_ai_output_text: nil,
      language_processing_ai_input_text: nil,
      language_processing_ai_output_text: nil,
      voice_generator_ai_input_text: nil,
      voice_generator_ai_audio_file_key: nil
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


  def save_speech_recognition_transcription_ai_data(user_id, audio_file_key: nil, output_text: nil)
    self.data[:speech_recognition_transcription_ai_audio_file_key] = audio_file_key unless audio_file_key.nil?
    self.data[:speech_recognition_transcription_ai_output_text] = output_text
  end

  def save_language_processing_ai_data(user_id, input_text: nil, interlocutor_output_text: nil, corrector_output_text: nil)
    self.data[:language_processing_ai_input_text] = input_text
    self.data[:language_processing_ai_interlocutor_output_text] = interlocutor_output_text
    self.data[:language_processing_ai_corrector_output_text] = corrector_output_text
  end

  def save_voice_generator_ai_data(user_id, input_text: nil, audio_file_key: nil)
    self.data[:voice_generator_ai_input_text] = input_text
    self.data[:voice_generator_ai_audio_file_key] = audio_file_key
  end
  
end