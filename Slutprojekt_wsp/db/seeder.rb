require 'sqlite3'
require 'bcrypt'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    ['cart_items', 'carts', 'products', 'categories', 'users'].each do |table|
      db.execute("DROP TABLE IF EXISTS #{table}")
    end
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT NOT NULL UNIQUE,
                  password_digest TEXT NOT NULL,
                  role TEXT DEFAULT "user")')

    db.execute('CREATE TABLE categories (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL UNIQUE)')

    db.execute('CREATE TABLE products (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  description TEXT,
                  price REAL NOT NULL,
                  stock INTEGER DEFAULT 0,
                  category_id INTEGER,
                  FOREIGN KEY(category_id) REFERENCES categories(id))')

    db.execute('CREATE TABLE carts (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NOT NULL,
                  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE)')

    db.execute('CREATE TABLE cart_items (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  cart_id INTEGER NOT NULL,
                  product_id INTEGER NOT NULL,
                  quantity INTEGER NOT NULL DEFAULT 1,
                  FOREIGN KEY(cart_id) REFERENCES carts(id) ON DELETE CASCADE,
                  FOREIGN KEY(product_id) REFERENCES products(id))')
  end

  def self.populate_tables
    users = [
      { username: 'admin', password: 'admin123', role: 'admin' },
      { username: 'Yad', password: 'password123', role: 'user' },
      { username: 'Päronmannen', password: 'password123', role: 'user' },
      { username: 'John Doe', password: 'password123', role: 'user' }
    ]

    users.each do |u|
      hashed_pw = BCrypt::Password.create(u[:password])
      db.execute('INSERT INTO users (username, password_digest, role) VALUES (?, ?, ?)', 
                 [u[:username], hashed_pw, u[:role]])
    end

    ['Avgassystem', 'Fälgar', 'Däck'].each do |category_name|
      db.execute('INSERT INTO categories (name) VALUES (?)', [category_name])
    end

    products = [
      { name: 'Sportavgassystem', description: 'Sportigt avgassystem i titan', price: 2499, stock: 5, category_id: 1 },
      { name: 'Fälg 18 tum', description: 'Aluminiumfälg 18 tum', price: 1290, stock: 8, category_id: 2 },
      { name: 'Vinterdäck 225/45R17', description: 'Dubbdäck för vinterväglag', price: 899, stock: 12, category_id: 3 }
    ]

    products.each do |p|
      db.execute('INSERT INTO products (name, description, price, stock, category_id) VALUES (?, ?, ?, ?, ?)', 
                 [p[:name], p[:description], p[:price], p[:stock], p[:category_id]])
    end
  end

  private

  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/development.sqlite')
    @db.results_as_hash = true
    @db.execute('PRAGMA foreign_keys = ON;')
    @db
  end
end

Seeder.seed!
