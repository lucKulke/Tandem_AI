class Conversation
  attr_accessor :iteration, :speech_recognition_transcription_ai, :language_processing_ai, :voice_generator_ai, :conversation_text
  
  def initialize(conversation_text)
    @conversation_text = conversation_text 
    @speech_recognition_transcription_ai = {}
    @language_processing_ai = {}
    @voice_generator_ai = {}
  end

  def data
    [self.speech_recognition_transcription_ai, self.language_processing_ai, self.voice_generator_ai]
  end


  def end_iteration
    self.conversation_text += "user: #{language_processing_ai[self.iteration][:input]}\nai: #{language_processing_ai[self.iteration][:output]}\n\n"
  end


  def speech_recognition_transcription_ai_data(audio_file_key, output_text, timestamp_input, timestamp_output, healthcode)
    @speech_recognition_transcription_ai = {
      audio_file_key: audio_file_key,
      output_text: output_text,
      timestamp_input: timestamp_input,
      timestamp_output: timestamp_output,
      healthcode: healthcode
    }
      
  end

  def language_processing_ai_data(input_text, output_text, timestamp_input, timestamp_output, healthcode)
    @language_processing_ai = {
      input_text: input_text,
      output_text: output_text,
      timestamp_input: timestamp_input,
      timestamp_output:timestamp_output,
      healthcode: healthcode
    }

  end

  def voice_generator_ai_data(input_text, audio_file_key, timestamp_input, timestamp_output, healthcode)
    @voice_generator_ai = {
      input_text: input_text,
      audio_file_key: audio_file_key,
      timestamp_input: timestamp_input,
      timestamp_output: timestamp_output,
      healthcode: healthcode
    }
  end
  
end

