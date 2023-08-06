class User
  attr_accessor :user_id, :iteration_id, :user_audio_reference, :ai_audio_reference, :conversation,
                :timestamp_speach_recognition_transcription_ai_input,
                :speech_recognition_transcription_ai_input, :speech_recognition_transcription_ai_output,
                :timestamp_speach_recognition_transcription_ai_output,
                :timestamp_language_processing_ai_input,
                :language_processing_ai_input, :language_processing_ai_output,
                :timestamp_language_processing_ai_output,
                :timestamp_voice_generator_ai_input,
                :voice_generator_ai_input, :voice_generator_ai_output,
                :timestamp_voice_generator_ai_output
                :health_code
end