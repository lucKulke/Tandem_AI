class IterationData
  attr_reader :speech_recognition_transcription_ai_audio_file_key,
              :speech_recognition_transcription_ai_output_text,
              :language_processing_ai_interlocutor_output_text,
              :language_processing_ai_corrector_output_text,
              :voice_generator_ai_audio_file_key

  def initialize(user_id, redis_connection)
    
    @speech_recognition_transcription_ai_audio_file_key = redis_connection.get("speech_recognition_transcription_ai_audio_file_key_#{user_id}")
    @speech_recognition_transcription_ai_output_text = redis_connection.get("speech_recognition_transcription_ai_output_text_#{user_id}")
    @language_processing_ai_interlocutor_output_text = redis_connection.get("language_processing_ai_interlocutor_output_text_#{user_id}")
    @language_processing_ai_corrector_output_text = redis_connection.get("language_processing_ai_corrector_output_text_#{user_id}")
    @voice_generator_ai_audio_file_key = redis_connection.get("voice_generator_ai_audio_file_key_#{user_id}")
    
  end

  def create
    last_added_section = [
      [{role: 'user', content: speech_recognition_transcription_ai_output_text}, {role: 'assistant', content: language_processing_ai_corrector_output_text}],
      {role: 'assistant', content: language_processing_ai_interlocutor_output_text}
    ] 
    
    {audio_file_key: voice_generator_ai_audio_file_key, user_text: speech_recognition_transcription_ai_output_text, ai_answer: language_processing_ai_interlocutor_output_text, section: last_added_section}
  end
  
end