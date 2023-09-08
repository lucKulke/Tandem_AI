require_relative 'conversation'
require_relative './database/database_connection'
require 'date'

class User
  attr_accessor :conversations
  attr_reader :user_id

  def initialize(user_id, db_connection)
    @user_id = user_id
    @conversations = load_conversations(user_id, db_connection)
  end

  def timestamp
    DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
  end

  def select_conversation(id)
    conversations.each{ |conversation| return conversation if conversation.id == id }
    nil
  end

  def create_conversation(db_connection)
    name = 'new Conversation'
    uuid = db_connection.create_uuid
    start_text = 'conversation start: '
    default_picture = '/images/robo.png'
    db_connection.create_conversation(self.user_id, uuid, name, default_picture, self.timestamp, 200)
  end

  def delete_conversation(conversation_id, db_connection)
    db_connection.delete_conversation(conversation_id, 404, self.timestamp)
  end


  def load_conversations(user_id, db_connection)
    return_format = []
    result = db_connection.select_conversation_id_and_name_and_picture(user_id, 200)
    result.each do |row|
      interlocutor_sections = db_connection.load_interlocutor_sections(row['conversation_id'])
      corrector_sections = db_connection.load_corrector_sections(row['conversation_id'])
      return_format << Conversation.new(row['conversation_id'], interlocutor_sections, corrector_sections, row['conversation_name'], row['conversation_picture'])
    end
    return_format
  end
end 