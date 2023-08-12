require 'net/http'
class LanguageProcessingAI

  def initialize
    @system_message = "You are a helpful assistant"
  end

  def generate_response(conversation)
    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['CHAT_GPT_KEY']}"
    }

    payload = {
      model: 'gpt-3.5-turbo',
      messages: conversation,
      max_tokens: 100
    }

    response = http.post(uri.path, payload.to_json, headers)
    response_body = JSON.parse(response.body)

    response_body['choices'][0]['message']['content']
  end
end

class VoiceGeneratorAI
end