require 'net/http'
class LanguageProcessingAI

  def self.generate_response(conversation)
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

  def self.summarise_text_to_title(sections)
    sections.unshift({role: "system", content: "Summarize the conversation as short as possible to a title" })
    
    uri = URI.parse('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['CHAT_GPT_KEY']}"
    }

    payload = {
      model: 'gpt-3.5-turbo',
      messages: sections,
      max_tokens: 12
    }

    response = http.post(uri.path, payload.to_json, headers)
    response_body = JSON.parse(response.body)
    response_body['choices'][0]['message']['content']
  end
end


class Interlocutor < LanguageProcessingAI
  SYSTEM_MESSAGE = "Try to have a conversation with the user.".freeze
  def self.generate_response(conversation)
    conversation.unshift({role: 'system', content: SYSTEM_MESSAGE})
    super(conversation)
  end
end

class Corrector < LanguageProcessingAI
  SYSTEM_MESSAGE = "Correct the grammar from the user".freeze
  def self.generate_response(conversation)
    conversation.unshift({role: 'system', content: SYSTEM_MESSAGE})
    super(conversation)
  end
end


class VoiceGeneratorAI
end