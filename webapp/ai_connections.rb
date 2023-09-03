require 'net/http'
class LanguageProcessingAI

  def self.generate_response(token, *instances)

    instance_list = {}

    instances.each do |instance|
      instance_list[instance.name.to_sym] = {
        system_message: instance.system_message,
        sections: instance.conversation
      }
    end

    uri = URI.parse('http://localhost:8081/chat_gpt')
    http = Net::HTTP.new(uri.host, uri.port)

    headers = {
      'Content-Type' => 'application/json'
    }

    payload = {
      instances: instance_list,
      model: 'gpt-3.5-turbo',
      token: token
    }


    puts payload.to_json

    response = http.post(uri.path, payload.to_json, headers)
    response_body = JSON.parse(response.body)
    answer = []
    puts
    p response_body
    puts
    response_body.each do |instance_name, data|
      answer << data['content']
    end
    return answer[0] if answer.size == 1 
    answer
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

class ChatInstance
  attr_reader :conversation, :system_message, :name
  def initialize(name, system_message, conversation)
    @conversation = conversation
    @system_message = system_message
    @name = name
  end
end

class Interlocutor < ChatInstance
  def initialize(conversation)
    super('interlocutor', 'Try to have a conversation with the user and keep your answer short.', conversation)
  end
end

class Corrector < ChatInstance
  def initialize(conversation)
    super('corrector', 'Correct the grammer of the user', conversation)
  end
end

class Summarizer < ChatInstance
  def initialize(conversation)
    super('summerizer', 'Summarize the conversation as short as possible to a title.', conversation)
  end
end

class Artist < LanguageProcessingAI

  def self.create_image(text)
    url = self.dalle_generate_response(text)
    folder = "./public/images/"
    tempfile = Down.download(url)
    FileUtils.mv(tempfile.path, folder + tempfile.original_filename)
    "/images/" + tempfile.original_filename
  end

  def self.dalle_generate_response(text)
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
    response_body['data'][0]['url']
  end
  
end


class SpeechRecogTransAI
  def self.generate_response(audio_file_url)
    url = URI("http://localhost:8080/invocations")

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

