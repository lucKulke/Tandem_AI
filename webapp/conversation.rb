class Conversation
  attr_accessor :iteration, :user_labelling, :ai_labelling, :conversation_text, :name, :conversation_data, :conversation_id, :foramatted_conversation
  
  def initialize(conversation_id, conversation_text, conversation_name, user_labelling, ai_labelling)
    @conversation_id = conversation_id
    @conversation_text = conversation_text
    @user_labelling = user_labelling
    @ai_labelling = ai_labelling
    @name = conversation_name
    reset
  end

  def reset
    @conversation_data = {
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

  def format_conversation(text, user, ai)
    user_labelling = user
    ai_labelling = ai
    formantted_version = []
  
    text.split(user_labelling).each do |substring1|
      user = substring1[/^(.*)#{ai_labelling}/, 1]
      formantted_version << {role: 'user', content: user} unless user.nil?
      ai = substring1[/#{ai_labelling}(.*)/, 1]
      formantted_version << {role: 'system', content: ai } unless ai.nil?
    end
    formantted_version
  end


  def client_information
    {audio_file_key: self.conversation_data[:voice_generator_ai_audio_file_key], user_text: self.conversation_data[:speech_recognition_transcription_ai_output_text], ai_answer: self.conversation_data[:language_processing_ai_output_text], conversation_text: conversation_text}
  end


  def end_iteration
    self.conversation_text += "user: #{self.conversation_data[:speech_recognition_transcription_ai_output_text]}\nai: #{self.conversation_data[:language_processing_ai_output_text]}\n\n"
    reset
  end


  def speech_recognition_transcription_ai_data(audio_file_key, output_text, timestamp_input, timestamp_output, healthcode)
      conversation_data[:speech_recognition_transcription_ai_audio_file_key] = audio_file_key
      conversation_data[:speech_recognition_transcription_ai_output_text] = output_text,
      conversation_data[:speech_recognition_transcription_ai_timestamp_input] = timestamp_input,
      conversation_data[:speech_recognition_transcription_ai_timestamp_output] = timestamp_output,
      conversation_data[:speech_recognition_transcription_ai_healthcode] = healthcode 
  end

  def language_processing_ai_data(input_text, output_text, timestamp_input, timestamp_output, healthcode)
    conversation_data[:language_processing_ai_input_text] = audio_file_key
    conversation_data[:language_processing_ai_output_text] = output_text,
    conversation_data[:language_processing_ai_timestamp_input] = timestamp_input,
    conversation_data[:language_processing_ai_timestamp_output] = timestamp_output,
    conversation_data[:language_processing_ai_healthcode] = healthcode 
  end

  def voice_generator_ai_data(input_text, audio_file_key, timestamp_input, timestamp_output, healthcode)
    conversation_data[:voice_generator_ai_input_text] = audio_file_key
    conversation_data[:voice_generator_ai_output_audio_file_key] = output_text,
    conversation_data[:voice_generator_ai_timestamp_input] = timestamp_input,
    conversation_data[:voice_generator_ai_timestamp_output] = timestamp_output,
    conversation_data[:voice_generator_ai_healthcode] = healthcode 
  end
  
end

