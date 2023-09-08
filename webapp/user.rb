require_relative 'conversation'
require_relative './database/database_connection'
require 'date'

class User
  attr_accessor :current_conversation_id, :conversations
  attr_reader :user_id

  def initialize(user_id, db_connection)
    @user_id = user_id
    @conversations = load_conversations(user_id, db_connection)
    @current_conversation_id = nil
  end

  def timestamp
    DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
  end

  def select_current_conversation
    select_conversation(current_conversation_id)
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
    db_connection.create_conversation(self.user_id, uuid, name, default_picture, 0 ,start_text, self.timestamp, 200)
  end

  def delete_conversation(conversation_id, db_connection)
    db_connection.delete_conversation(conversation_id, 404, self.timestamp)
  end

  def enter_conversation(conversation_id)
    conversation = conversations.select do |conversation|
      conversation.conversation_id == conversation_id
    end
    
    self.current_conversation_id = conversation_id
    self.current_conversation = conversation.first
    self.current_conversation.reset
  end

  def load_conversations(user_id, db_connection)
    return_format = []
    result = db_connection.select_conversation_id_and_name_and_picture_and_picture_changed(user_id, 200)
    result.each do |row|
      interlocutor_sections = db_connection.load_interlocutor_sections(row['conversation_id'])
      corrector_sections = db_connection.load_corrector_sections(row['conversation_id'])
      picture_changed = row['conversation_picture_changed'] == 1 ? true : false
      return_format << Conversation.new(row['conversation_id'], interlocutor_sections, corrector_sections, row['conversation_name'], row['conversation_picture'], picture_changed)
    end
    return_format
  end
end 