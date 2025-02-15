require 'sqlite3'
require 'bcrypt'

class Seeder
  def self.seed!
    puts "Seeding database..."
    drop_tables
    create_tables
    populate_tables
    puts "Database seeded successfully."
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT NOT NULL)')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create("123")
    puts "Storing hashed version of password to db. Clear text never saved. #{password_hashed}"
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', ['Yad', password_hashed])
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', ['Päronmannen', password_hashed])
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', ['John Doe', password_hashed])
  end

  private

  def self.db
    @db ||= begin
      Dir.mkdir('db') unless Dir.exist?('db')
      db = SQLite3::Database.new('db/users.sqlite')
      db.results_as_hash = true
      db
    end
  end
end
