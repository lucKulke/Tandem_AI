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
      max_tokens: 500
    }

    response = http.post(uri.path, payload.to_json, headers)
    response_body = JSON.parse(response.body)
    response_body['choices'][0]['message']['content']
  end

  def summarise_text_to_title(conversation)
    text = [
      {role: "system", content: "You are a helpful assistant"},
      {role: "system", content: "Summarize the conversation as short as possible to a title and don't use ':'" },
      {role: "user", content: conversation}
    ]
    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['CHAT_GPT_KEY']}"
    }

    payload = {
      model: 'gpt-3.5-turbo',
      messages: text,
      max_tokens: 20
    }

    response = http.post(uri.path, payload.to_json, headers)
    response_body = JSON.parse(response.body)
    response_body['choices'][0]['message']['content']
  end
end

class VoiceGeneratorAI
end