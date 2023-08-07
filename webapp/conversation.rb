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

  def speech_recognition_transcription_ai_data(input_audio_file_ref, output, timestamp_input, timestamp_output, health_code)
    @@speech_recognition_transcription_ai[self.iteration] = { input_audio_file_ref: input_audio_file_ref,
                                                          output: output, timestamp_input: timestamp_input, timestamp_output: timestamp_output, health_code: health_code}
      
  end

  def language_processing_ai_data(input, output, timestamp_input, timestamp_output, health_code)
    @@language_processing_ai[self.iteration] = { input: input, output: output, timestamp_input: timestamp_input,
                                             timestamp_output: timestamp_output, health_code: health_code}

  end

  def voice_generator_ai_data(input, ouput_audio_file_ref, timestamp_input, timestamp_output, health_code)
    @@voice_generator_ai[self.iteration] = { input: input, ouput_audio_file_ref: ouput_audio_file_ref, timestamp_input: timestamp_input,
                                         timestamp_output: timestamp_output, health_code: health_code}
  end
  
end

