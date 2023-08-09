class LanguageProcessingAI

  def initialize(api_key: '')
    OpenAI.configure do |config|
      config.access_token = api_key
    end
    @system_message = "You are a helpful assistant"
  end

  def generate_response(conversation)
    response = OpenAI::ChatCompletion.create(
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: conversation },
                {role: 'system', content: @system_message}],
      temperature: 0.7
    )

    if response.key?('error')
      error_message = response['error']['message']
      assistant_response = [response['error']['code'], "An error occurred: #{error_message}"]
    else
      assistant_response = response.choices[0].message.content
    end
    assistant_response
  end

end

class VoiceGeneratorAI
end