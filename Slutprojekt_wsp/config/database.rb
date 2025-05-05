require 'sqlite3'

module DB
  def self.connection
    @connection ||= setup_database
  end

  private

  def self.setup_database
    db = SQLite3::Database.new('db/development.sqlite')
    db.results_as_hash = true
    db.execute('PRAGMA foreign_keys = ON')
    db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'") rescue nil
    
    db
  end
end