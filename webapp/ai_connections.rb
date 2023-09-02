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

  def self.create_image(text)
    
    uri = URI.parse('https://api.openai.com/v1/images/generations')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['CHAT_GPT_KEY']}"
    }

    payload = {
      prompt: text,
      n: 1,
      size: '512x512'
    }


    response = http.post(uri.path, payload.to_json, headers)
    response_body = JSON.parse(response.body)
    response_body['data'][0]['url']#['choices'][0]['message']['content']
  end
end


class Interlocutor < LanguageProcessingAI
  SYSTEM_MESSAGE = "Try to have a conversation with the user and keep your answer short.".freeze
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

class Artist < LanguageProcessingAI

  def self.create_image(text)
    url = super(text)
    folder = "./public/images/"
    tempfile = Down.download(url)
    FileUtils.mv(tempfile.path, folder + tempfile.original_filename)
    "/images/" + tempfile.original_filename
  end
  
end


class SpeechRecogTransAI
  def self.generate_response(audio_file_url)
    url = URI("http://localhost:8002/invocations")

    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Post.new(url)
    
    request.body = {input: audio_file_url, size: 'tiny'}.to_json

    response = http.request(request)
    responsebody = JSON.parse(response.body)
    p responsebody['predictions']['segments'][0][4]
    
  end
end

class VoiceGeneratorAI
  def self.generate_response(text)

    token = access_token
    uri = URI.parse('https://westeurope.tts.speech.microsoft.com/cognitiveservices/v1')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'X-Microsoft-OutputFormat' => 'riff-24khz-16bit-mono-pcm',
      'Content-Type' => 'application/ssml+xml',
      'Authorization' => "Bearer #{token}"
    }
      
    body = <<-End
<speak version='1.0' xml:lang='en-US'><voice xml:lang='en-US' xml:gender='Male'
name='en-US-ChristopherNeural'>
    #{text}
</voice></speak>
End

    response = http.post(uri.path, body , headers)

    response.body
  end

  def self.access_token
    uri = URI.parse('https://westeurope.api.cognitive.microsoft.com/sts/v1.0/issuetoken')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Ocp-Apim-Subscription-Key' => ENV['AZURE_SUBSCRIPTION_KEY']
    }
      
    response = http.post(uri.path, ''.to_json , headers)
    response.body
  end
end

