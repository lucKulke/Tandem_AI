class Conversation
  attr_accessor :iteration, :speech_recognition_transcription_ai, :language_processing_ai, :voice_generator_ai
  
  def initialize(conversation_text)
    @conversation_text = conversation_text 
    @iteration = 0
    @speech_recognition_transcription_ai = {}
    @language_processing_ai = {}
    @voice_generator_ai = {}
  end

  def start_iteration
    self.iteration += 1
  end

  def end_iteration
    self.conversation_text += "user: #{language_processing_ai[self.iteration][:input]}\nai: #{language_processing_ai[self.iteration][:output]}\n\n"
  end


  def speech_recognition_transcription_ai_data(audio_file_key, output_text, timestamp_input, timestamp_output, healthcode)
    @speech_recognition_transcription_ai[self.iteration] = {
      speech_recognition_transcription_audio_file_key: audio_file_key,
      speech_recognition_transcription_output: output_text,
      speech_recognition_transcription_timestamp_input: timestamp_input,
      speech_recognition_transcription_timestamp_output: timestamp_output,
      speech_recognition_transcription_healthcode: healthcode
    }
      
  end

  def language_processing_ai_data(input_text, output_text, timestamp_input, timestamp_output, healthcode)
    @language_processing_ai[self.iteration] = {
      language_processing_input: input_text,
      language_processing_output: output_text,
      language_processing_timestamp_input: timestamp_input,
      language_processing_timestamp_output:timestamp_output,
      language_processing_healthcode: healthcode
    }

  end

  def voice_generator_ai_data(input_text, audio_file_key, timestamp_input, timestamp_output, healthcode)
    @voice_generator_ai[self.iteration] = {
      voice_generator_input: input_text,
      voice_generator_audio_file_key: audio_file_key,
      voice_generator_timestamp_input: timestamp_input,
      voice_generator_timestamp_output: timestamp_output,
      voice_generator_healthcode: healthcode
    }
  end
  
end

