require "mysql2"

class DatabaseConnection
  attr_reader :establish

  DB_CONFIG = {
    host: 'localhost',
    port: '3206',
    username: 'root',
    password: 'halkopo2',
    database: 'tandem_ai'
  }

  def initialize
    @db = Mysql2::Client.new(DB_CONFIG)
  end

  def establish
    @db
  end
end

db = DatabaseConnection.new.establish

db.query('SELECT user_id FROM users WHERE first_name = "d"').each{|row| p row['user_id']}
