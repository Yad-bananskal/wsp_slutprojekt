require 'sqlite3'
require 'bcrypt'

class Seeder
  def self.seed!
    puts "Seeding database..."

    # Connect to the database
    db = SQLite3::Database.new "db/development.sqlite"
    db.results_as_hash = true

    # Enable foreign keys in SQLite
    db.execute "PRAGMA foreign_keys = ON;"

    # Drop existing tables
    drop_tables(db)

    # Create tables
    create_tables(db)

    # Populate tables with data
    populate_tables(db)

    puts "Database seeded successfully."
  end

  def self.drop_tables(db)
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS tasks')
  end

  def self.create_tables(db)
    # Create the users table (without the email column)
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password_digest TEXT NOT NULL
      );
    SQL

    # Create the tasks table
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT,
          user_id INTEGER,
          due TEXT,
          status TEXT,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    SQL
  end

  def self.populate_tables(db)
    # Insert sample users (without email)
    db.execute "INSERT INTO users (username, password_digest) VALUES (?, ?)", ["alice", "hashed_password_1"]
    db.execute "INSERT INTO users (username, password_digest) VALUES (?, ?)", ["bob", "hashed_password_2"]

    # Insert sample tasks
    db.execute "INSERT INTO tasks (description, user_id, due, status) VALUES (?, ?, ?, ?)", ["Buy groceries", 1, "2025-02-20", "pending"]
    db.execute "INSERT INTO tasks (description, user_id, due, status) VALUES (?, ?, ?, ?)", ["Finish project", 2, "2025-02-25", "in-progress"]

    # Insert additional users with hashed passwords (without email)
    password_hashed = BCrypt::Password.create("123")
    puts "Storing hashed version of password to db. Clear text never saved. #{password_hashed}"
    db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', ['Yad', password_hashed])
    db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', ['Päronmannen', password_hashed])
    db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', ['John Doe', password_hashed])
  end
end

# Run the seeder
Seeder.seed!