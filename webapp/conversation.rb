class Conversation
  attr_accessor :iteration, :name, :data, :id, :interlocutor_sections, :corrector_sections, :picture
  
  def initialize(conversation_id, interlocutor_sections, corrector_sections, name, picture)
    @id = conversation_id
    @interlocutor_sections = interlocutor_sections
    @corrector_sections = corrector_sections
    @picture = picture
    @name = name
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

end